const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

admin.initializeApp();
const db = admin.firestore();

// Cache configuration
let configCache = {
  twilioConfig: null,
  otpConfig: null,
  lastFetch: 0,
  cacheDuration: 5 * 60 * 1000
};

// Get config from Firestore
async function getConfig() {
  const now = Date.now();
  
  if (configCache.twilioConfig && 
      configCache.otpConfig && 
      (now - configCache.lastFetch) < configCache.cacheDuration) {
    return {
      twilioConfig: configCache.twilioConfig,
      otpConfig: configCache.otpConfig
    };
  }

  try {
    const twilioDoc = await db.collection('app_config').doc('twilio_config').get();
    const twilioConfig = twilioDoc.data();

    const otpDoc = await db.collection('app_config').doc('otp_config').get();
    const otpConfig = otpDoc.data();

    configCache = {
      twilioConfig,
      otpConfig,
      lastFetch: now,
      cacheDuration: 5 * 60 * 1000
    };

    return { twilioConfig, otpConfig };
  } catch (error) {
    console.error('Error getting config:', error);
    throw new functions.https.HttpsError('internal', 'Configuration error');
  }
}

// Generate OTP
function generateOTP(length = 6) {
  const min = Math.pow(10, length - 1);
  const max = Math.pow(10, length) - 1;
  return Math.floor(min + Math.random() * (max - min + 1)).toString();
}

// ✅ ENVOYER OTP PAR SMS
exports.sendSMSOTP = functions.https.onCall(async (data, context) => {
  const { phoneNumber } = data;

  console.log('📞 SMS OTP request:', phoneNumber);

  if (!phoneNumber) {
    throw new functions.https.HttpsError('invalid-argument', 'Phone number required');
  }

  try {
    const { twilioConfig, otpConfig } = await getConfig();

    if (!twilioConfig.enabled) {
      throw new functions.https.HttpsError('unavailable', 'Service unavailable');
    }

    const twilioClient = twilio(twilioConfig.accountSid, twilioConfig.authToken);
    const otp = generateOTP(otpConfig.otpLength);
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      Date.now() + otpConfig.expiryMinutes * 60 * 1000
    );

    // Sauvegarder OTP
    await db.collection('otp_codes').doc(phoneNumber).set({
      code: otp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt,
      verified: false,
      attempts: 0,
      maxAttempts: otpConfig.maxAttempts,
    });

    console.log('💾 OTP saved:', otp);

    // Formater le numéro
    const cleanPhoneNumber = phoneNumber.replace(/\s+/g, '');
    const formattedPhoneNumber = cleanPhoneNumber.startsWith('+') 
      ? cleanPhoneNumber 
      : `+${cleanPhoneNumber}`;

    console.log('📱 Sending SMS to:', formattedPhoneNumber);

    // ✅ ENVOYER PAR SMS
    const message = await twilioClient.messages.create({
      from: twilioConfig.smsNumber,  // Votre numéro SMS Twilio
      to: formattedPhoneNumber,
      body: `Sendy - Code: ${otp}\nExpire dans ${otpConfig.expiryMinutes} minutes.\n\nNe partagez jamais ce code.`
    });

    console.log('✅ SMS sent:', message.sid);

    await db.collection('otp_logs').add({
      phoneNumber: phoneNumber,
      messageSid: message.sid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
      method: 'sms'
    });

    return { 
      success: true,
      message: 'Code sent via SMS',
      expiryMinutes: otpConfig.expiryMinutes,
      messageSid: message.sid
    };

  } catch (error) {
    console.error('❌ SMS error:', error);
    
    await db.collection('otp_logs').add({
      phoneNumber: phoneNumber,
      error: error.message,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'failed',
      method: 'sms'
    });

    throw new functions.https.HttpsError('internal', `Error: ${error.message}`);
  }
});

// ✅ POINT D'ENTRÉE - Rediriger vers SMS
exports.sendWhatsAppOTP = functions.https.onCall(async (data, context) => {
  console.log('🔀 Routing to SMS');
  return await exports.sendSMSOTP.run(data, context);
});

// ✅ VÉRIFIER OTP - SANS CUSTOM TOKEN
exports.verifyWhatsAppOTP = functions.https.onCall(async (data, context) => {
  const { phoneNumber, code } = data;

  console.log('📥 verifyWhatsAppOTP:', { phoneNumber, code });

  if (!phoneNumber || !code) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing parameters');
  }

  try {
    const otpDoc = await db.collection('otp_codes').doc(phoneNumber).get();

    if (!otpDoc.exists) {
      console.log('❌ OTP not found');
      throw new functions.https.HttpsError('not-found', 'Invalid or expired code');
    }

    const otpData = otpDoc.data();
    console.log('📋 OTP data:', otpData);

    if (otpData.verified) {
      console.log('❌ Already verified');
      throw new functions.https.HttpsError('already-exists', 'Code already used');
    }

    if (otpData.expiresAt.toMillis() < Date.now()) {
      console.log('❌ Expired');
      throw new functions.https.HttpsError('deadline-exceeded', 'Code expired');
    }

    if (otpData.attempts >= otpData.maxAttempts) {
      console.log('❌ Too many attempts');
      throw new functions.https.HttpsError('resource-exhausted', 'Too many attempts');
    }

    if (otpData.code !== code) {
      console.log('❌ Incorrect code');
      await otpDoc.ref.update({
        attempts: admin.firestore.FieldValue.increment(1)
      });
      throw new functions.https.HttpsError('invalid-argument', 'Incorrect code');
    }

    // ✅ CODE CORRECT
    console.log('✅ Code is correct!');
    
    await otpDoc.ref.update({ 
      verified: true,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    const uid = phoneNumber.replace(/[^0-9]/g, '');

    console.log('✅ OTP verified for:', phoneNumber, 'UID:', uid);

    await db.collection('otp_logs').add({
      phoneNumber: phoneNumber,
      action: 'verified',
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'success',
    });

    // ✅ RETOUR SIMPLE - PAS DE CUSTOM TOKEN
    return { 
      success: true, 
      uid: uid,
      phoneNumber: phoneNumber,
      message: 'Verification successful'
    };

  } catch (error) {
    console.error('❌ Verify error:', error.message);
    
    await db.collection('otp_logs').add({
      phoneNumber: phoneNumber,
      action: 'verify_failed',
      error: error.message,
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'failed',
    });

    if (error.code) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Resend OTP
exports.resendWhatsAppOTP = functions.https.onCall(async (data, context) => {
  const { phoneNumber } = data;

  if (!phoneNumber) {
    throw new functions.https.HttpsError('invalid-argument', 'Phone number required');
  }

  try {
    const { otpConfig } = await getConfig();
    const otpDoc = await db.collection('otp_codes').doc(phoneNumber).get();

    if (otpDoc.exists) {
      const lastSent = otpDoc.data().createdAt?.toMillis() || 0;
      const now = Date.now();
      const cooldown = otpConfig.resendCooldownSeconds * 1000;

      if (now - lastSent < cooldown) {
        const remainingSeconds = Math.ceil((cooldown - (now - lastSent)) / 1000);
        throw new functions.https.HttpsError(
          'resource-exhausted', 
          `Wait ${remainingSeconds} seconds`
        );
      }
    }

    return await exports.sendWhatsAppOTP.run(data, context);

  } catch (error) {
    console.error('Resend error:', error);
    if (error.code) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Error resending code');
  }
});