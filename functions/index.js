const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');
const nodemailer = require('nodemailer');

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

// ============================================
// FCM PUSH NOTIFICATION SYSTEM
// ============================================

// Send FCM push notification to a specific user by their FCM token
async function sendFCMNotification(fcmToken, title, body, data = {}) {
  if (!fcmToken) return;

  try {
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data,
      android: {
        notification: {
          channelId: 'sendy_channel',
          priority: 'high',
          sound: 'default',
        },
      },
    };

    await admin.messaging().send(message);
    console.log('✅ FCM notification sent:', title);
  } catch (error) {
    console.error('❌ FCM send error:', error.message);
  }
}

// ✅ TRIGGER: New order created → notify restaurant
exports.onNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const orderData = snap.data();
    const orderId = context.params.orderId;

    // Notify the restaurant
    try {
      const restaurantDoc = await db.collection('users').doc(orderData.restaurantId).get();
      if (restaurantDoc.exists) {
        const restaurant = restaurantDoc.data();
        if (restaurant.fcmToken) {
          const itemCount = orderData.items ? orderData.items.length : 0;
          const total = orderData.total || 0;
          await sendFCMNotification(
            restaurant.fcmToken,
            'Nouvelle commande !',
            `${itemCount} article(s) - ${total} DHs\n${orderData.clientComment || ''}`,
            { orderId: orderId, type: 'new_order' }
          );
        }
      }
    } catch (e) {
      console.error('Error notifying restaurant:', e);
    }
  });

// ✅ TRIGGER: Order accepted by restaurant → notify all delivery in same city
exports.onOrderAccepted = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Check if status changed to accepted (index 1)
    if (before.status !== 1 && after.status === 1) {
      try {
        // Get restaurant city
        const restaurantDoc = await db.collection('users').doc(after.restaurantId).get();
        if (!restaurantDoc.exists) return;

        const restaurantData = restaurantDoc.data();
        const restaurantCity = restaurantData.city || '';
        const restaurantName = restaurantData.restaurantName || restaurantData.name || 'Restaurant';

        // Get all approved delivery persons in same city (or all if no city)
        let deliveryQuery = db.collection('users')
          .where('userType', '==', 1) // delivery
          .where('approvalStatus', '==', 1); // approved

        if (restaurantCity) {
          deliveryQuery = deliveryQuery.where('city', '==', restaurantCity);
        }

        const deliverySnapshot = await deliveryQuery.get();

        console.log(`📦 Order ${orderId} accepted - notifying ${deliverySnapshot.size} delivery persons in ${restaurantCity || 'all cities'}`);

        const notificationPromises = [];
        deliverySnapshot.forEach((doc) => {
          const delivery = doc.data();
          if (delivery.fcmToken) {
            const itemCount = after.items ? after.items.length : 0;
            notificationPromises.push(
              sendFCMNotification(
                delivery.fcmToken,
                `Livraison disponible - ${restaurantName}`,
                `${itemCount} article(s) - ${after.total || 0} DHs - ${after.deliveryAddress || ''}`,
                { orderId: orderId, type: 'delivery_available' }
              )
            );
          }
        });

        await Promise.all(notificationPromises);
      } catch (e) {
        console.error('Error notifying delivery persons:', e);
      }
    }

    // Order picked up by delivery → notify client
    if (before.status !== 2 && after.status === 2 && after.deliveryPersonId) {
      try {
        const clientDoc = await db.collection('users').doc(after.clientId).get();
        if (clientDoc.exists) {
          const client = clientDoc.data();
          if (client.fcmToken) {
            await sendFCMNotification(
              client.fcmToken,
              'Commande en cours de livraison',
              'Votre commande est en route !',
              { orderId: orderId, type: 'order_in_progress' }
            );
          }
        }
      } catch (e) {
        console.error('Error notifying client:', e);
      }
    }

    // Order delivered → notify client
    if (before.status !== 3 && after.status === 3) {
      try {
        const clientDoc = await db.collection('users').doc(after.clientId).get();
        if (clientDoc.exists) {
          const client = clientDoc.data();
          if (client.fcmToken) {
            await sendFCMNotification(
              client.fcmToken,
              'Commande livrée !',
              'Votre commande a été livrée. Bon appétit !',
              { orderId: orderId, type: 'order_delivered' }
            );
          }
        }
      } catch (e) {
        console.error('Error notifying client:', e);
      }
    }
  });

// ============================================
// EMAIL NOTIFICATION SYSTEM
// ============================================

// Get email config from admin_mail collection
async function getEmailConfig() {
  try {
    const configDoc = await db.collection('admin_mail').doc('config').get();
    if (!configDoc.exists) {
      console.log('⚠️ No email config found in admin_mail collection');
      return null;
    }
    return configDoc.data();
  } catch (error) {
    console.error('Error getting email config:', error);
    return null;
  }
}

// Create email transporter
async function createTransporter(emailConfig) {
  return nodemailer.createTransport({
    host: emailConfig.smtpHost || 'smtp.gmail.com',
    port: emailConfig.smtpPort || 587,
    secure: emailConfig.smtpSecure || false,
    auth: {
      user: emailConfig.smtpUser,
      pass: emailConfig.smtpPassword,
    },
  });
}

// Send admin notification email
async function sendAdminEmail(subject, htmlBody) {
  const emailConfig = await getEmailConfig();
  if (!emailConfig || !emailConfig.enabled) {
    console.log('📧 Email notifications disabled or not configured');
    return;
  }

  try {
    const transporter = await createTransporter(emailConfig);
    const adminEmails = emailConfig.adminEmails || [];

    if (adminEmails.length === 0) {
      console.log('⚠️ No admin emails configured');
      return;
    }

    const mailOptions = {
      from: `"Sendy Admin" <${emailConfig.smtpUser}>`,
      to: adminEmails.join(', '),
      subject: `[Sendy] ${subject}`,
      html: htmlBody,
    };

    await transporter.sendMail(mailOptions);
    console.log('✅ Admin email sent:', subject);

    // Log the email
    await db.collection('admin_mail').doc('logs').collection('sent').add({
      subject: subject,
      recipients: adminEmails,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
    });
  } catch (error) {
    console.error('❌ Error sending admin email:', error);
    await db.collection('admin_mail').doc('logs').collection('sent').add({
      subject: subject,
      error: error.message,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'failed',
    });
  }
}

// ✅ TRIGGER: New restaurant or delivery user registration (pending approval)
exports.onNewUserRegistration = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const userId = context.params.userId;

    // Only notify for restaurant and delivery users
    if (userData.userType !== 2 && userData.userType !== 1) {
      return; // 0=client, 1=delivery, 2=restaurant, 3=admin
    }

    const userTypeName = userData.userType === 2 ? 'Restaurant' : 'Livreur';
    const userName = userData.name || userData.restaurantName || 'N/A';

    const subject = `Nouvelle demande d'inscription - ${userTypeName}`;
    const htmlBody = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background-color: #FF5722; padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">SENDY</h1>
          <p style="color: rgba(255,255,255,0.8); margin: 5px 0 0 0;">Nouvelle demande d'inscription</p>
        </div>
        <div style="padding: 20px; background-color: #f9f9f9;">
          <h2 style="color: #333;">Nouveau ${userTypeName}</h2>
          <table style="width: 100%; border-collapse: collapse;">
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Type:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${userTypeName}</td></tr>
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Nom:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${userName}</td></tr>
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Telephone:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${userData.phoneNumber}</td></tr>
            ${userData.restaurantName ? `<tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Restaurant:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${userData.restaurantName}</td></tr>` : ''}
            <tr><td style="padding: 8px;"><strong>Date:</strong></td><td style="padding: 8px;">${new Date().toLocaleString('fr-FR')}</td></tr>
          </table>
          <p style="margin-top: 20px; text-align: center;">
            <em>Connectez-vous au panneau d'administration pour approuver ou rejeter cette demande.</em>
          </p>
        </div>
      </div>
    `;

    await sendAdminEmail(subject, htmlBody);
  });

// ✅ TRIGGER: New menu item created (needs approval)
exports.onNewMenuItem = functions.firestore
  .document('menuItems/{itemId}')
  .onCreate(async (snap, context) => {
    const itemData = snap.data();
    const itemId = context.params.itemId;

    // Get restaurant name
    let restaurantName = 'Restaurant inconnu';
    try {
      const restaurantDoc = await db.collection('users').doc(itemData.restaurantId).get();
      if (restaurantDoc.exists) {
        const rData = restaurantDoc.data();
        restaurantName = rData.restaurantName || rData.name || 'Restaurant inconnu';
      }
    } catch (e) { /* ignore */ }

    const subject = `Nouveau plat a valider - ${itemData.name}`;
    const htmlBody = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background-color: #FF5722; padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">SENDY</h1>
          <p style="color: rgba(255,255,255,0.8); margin: 5px 0 0 0;">Nouveau plat a valider</p>
        </div>
        <div style="padding: 20px; background-color: #f9f9f9;">
          <h2 style="color: #333;">Nouveau plat ajouté</h2>
          <table style="width: 100%; border-collapse: collapse;">
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Restaurant:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${restaurantName}</td></tr>
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Nom du plat:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${itemData.name}</td></tr>
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Prix:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${itemData.price} DHs</td></tr>
            <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Categorie:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${itemData.category}</td></tr>
            <tr><td style="padding: 8px;"><strong>Date:</strong></td><td style="padding: 8px;">${new Date().toLocaleString('fr-FR')}</td></tr>
          </table>
          <p style="margin-top: 20px; text-align: center;">
            <em>Connectez-vous au panneau d'administration pour approuver ou rejeter ce plat.</em>
          </p>
        </div>
      </div>
    `;

    await sendAdminEmail(subject, htmlBody);
  });

// ✅ TRIGGER: Menu item updated (e.g. edit)
exports.onMenuItemUpdated = functions.firestore
  .document('menuItems/{itemId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const itemId = context.params.itemId;

    // Only notify if status changed to pending (re-submission after edit)
    if (before.status !== 'pending' && after.status === 'pending') {
      let restaurantName = 'Restaurant inconnu';
      try {
        const restaurantDoc = await db.collection('users').doc(after.restaurantId).get();
        if (restaurantDoc.exists) {
          const rData = restaurantDoc.data();
          restaurantName = rData.restaurantName || rData.name || 'Restaurant inconnu';
        }
      } catch (e) { /* ignore */ }

      const subject = `Plat modifie a revalider - ${after.name}`;
      const htmlBody = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #FF5722; padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0;">SENDY</h1>
            <p style="color: rgba(255,255,255,0.8); margin: 5px 0 0 0;">Plat modifie</p>
          </div>
          <div style="padding: 20px; background-color: #f9f9f9;">
            <h2 style="color: #333;">Plat modifié - Revalidation requise</h2>
            <table style="width: 100%; border-collapse: collapse;">
              <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Restaurant:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${restaurantName}</td></tr>
              <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Plat:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${after.name}</td></tr>
              <tr><td style="padding: 8px;"><strong>Prix:</strong></td><td style="padding: 8px;">${after.price} DHs</td></tr>
            </table>
          </div>
        </div>
      `;

      await sendAdminEmail(subject, htmlBody);
    }
  });

// ✅ TRIGGER: User profile image change (pending approval)
exports.onProfileImageChange = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    // Only notify if hasPendingImageChange went from false to true
    if (!before.hasPendingImageChange && after.hasPendingImageChange) {
      const userTypeName = after.userType === 2 ? 'Restaurant' : 'Livreur';
      const userName = after.restaurantName || after.name || after.phoneNumber;

      const subject = `Changement d'image - ${userTypeName}: ${userName}`;
      const htmlBody = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #FF5722; padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0;">SENDY</h1>
            <p style="color: rgba(255,255,255,0.8); margin: 5px 0 0 0;">Demande de changement d'image</p>
          </div>
          <div style="padding: 20px; background-color: #f9f9f9;">
            <h2 style="color: #333;">Changement d'image de profil</h2>
            <table style="width: 100%; border-collapse: collapse;">
              <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Type:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${userTypeName}</td></tr>
              <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Nom:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${userName}</td></tr>
              <tr><td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Telephone:</strong></td><td style="padding: 8px; border-bottom: 1px solid #eee;">${after.phoneNumber}</td></tr>
              <tr><td style="padding: 8px;"><strong>Date:</strong></td><td style="padding: 8px;">${new Date().toLocaleString('fr-FR')}</td></tr>
            </table>
            <p style="margin-top: 20px; text-align: center;">
              <em>Connectez-vous au panneau d'administration pour approuver ou rejeter ce changement d'image.</em>
            </p>
          </div>
        </div>
      `;

      await sendAdminEmail(subject, htmlBody);
    }
  });