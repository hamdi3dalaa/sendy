// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _verificationId;
  String? _currentPhoneNumber;
  UserModel? _currentUser;
  Locale _locale = const Locale('fr');

  UserModel? get currentUser => _currentUser;
  Locale get locale => _locale;

  AuthProvider() {
    _loadLanguage();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'fr';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> changeLanguage(String langCode) async {
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      print('🟦 [AUTH_PROVIDER] Auth state changed: ${user.uid}');

      try {
        // ✅ ADD TIMEOUT to prevent hanging
        final doc =
            await _firestore.collection('users').doc(user.uid).get().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏱️ [AUTH_PROVIDER] Timeout loading user document');
            throw TimeoutException('User document load timeout');
          },
        );

        if (doc.exists) {
          print('🟢 [AUTH_PROVIDER] User document found');
          final data = doc.data()!;

          print('═══════════════════════════════════════');
          print('📊 [AUTH_PROVIDER] USER DATA:');
          print('   - phoneNumber: ${data['phoneNumber']}');
          print('   - name: ${data['name']}');
          print(
              '   - userType: ${data['userType']} (${data['userType'].runtimeType})');
          print('   - approvalStatus: ${data['approvalStatus']}');
          print('═══════════════════════════════════════');

          _currentUser = UserModel.fromMap(data);

          print('👤 [AUTH_PROVIDER] UserModel created:');
          print('   - userType: ${_currentUser!.userType}');
          print('   - isAdmin: ${_currentUser!.isAdmin}');
          print('   - userTypeString: ${_currentUser!.userTypeString}');

          notifyListeners();
          print('✅ [AUTH_PROVIDER] notifyListeners called');
        } else {
          print('🟡 [AUTH_PROVIDER] User document not found');
          _currentUser = null;
          notifyListeners();
        }
      } on TimeoutException catch (e) {
        print('❌ [AUTH_PROVIDER] Timeout: $e');
        _currentUser = null;
        notifyListeners();
      } catch (e, stackTrace) {
        print('🔴 [AUTH_PROVIDER] Error loading user: $e');
        print('🔴 [AUTH_PROVIDER] Stack trace: $stackTrace');
        _currentUser = null;
        notifyListeners();
      }
    } else {
      print('🟡 [AUTH_PROVIDER] User signed out');
      _currentUser = null;
      notifyListeners();
    }
  }

  // ✅ FIREBASE PHONE AUTH - GRATUIT
  Future<void> sendPhoneOTP(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    print('🔵 [AUTH_PROVIDER] Sending OTP to: $phoneNumber');
    _currentPhoneNumber = phoneNumber;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🟢 [AUTH_PROVIDER] Auto-verification completed');
          // Auto-vérification (Android uniquement)
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            print('Error auto-signing in: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔴 [AUTH_PROVIDER] Verification failed: ${e.message}');
          onError(e.message ?? 'Erreur de vérification');
        },
        codeSent: (String verificationId, int? resendToken) {
          print(
              '🟢 [AUTH_PROVIDER] Code sent! Verification ID: $verificationId');
          _verificationId = verificationId;
          onCodeSent('Code envoyé par SMS');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print('🔴 [AUTH_PROVIDER] Error: $e');
      onError(e.toString());
    }
  }

  // Vérifier OTP et créer utilisateur
  Future<bool> verifyPhoneOTP(
    String code,
    UserType userType, {
    String? name,
    String? idCardUrl,
    String? restaurantName,
  }) async {
    print('🔵 [AUTH_PROVIDER] Verifying code: $code');

    if (_verificationId == null) {
      throw Exception('Aucun code de vérification en cours');
    }

    try {
      // Créer les credentials
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      // ✅ ENTOURER DE TRY-CATCH POUR L'ERREUR DE TYPE
      UserCredential? userCredential;
      User? user;

      try {
        userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;
        print('🟢 [AUTH_PROVIDER] User signed in: ${user?.uid}');
      } catch (typeError) {
        print(
            '🟡 [AUTH_PROVIDER] Type error caught, getting current user instead');
        // Si erreur de type, récupérer l'utilisateur actuel
        user = _auth.currentUser;
        print('🟢 [AUTH_PROVIDER] Current user: ${user?.uid}');
      }

      if (user != null) {
        // Attendre que l'auth se stabilise
        await Future.delayed(const Duration(milliseconds: 500));

        // Vérifier si utilisateur existe
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          print('🟢 [AUTH_PROVIDER] Existing user');
          final data = userDoc.data()!;

          // Mettre à jour FCM token
          final fcmToken = await _messaging.getToken();
          if (fcmToken != null && data['fcmToken'] != fcmToken) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'fcmToken': fcmToken});
            data['fcmToken'] = fcmToken;
          }

          _currentUser = UserModel.fromMap(data);
        } else {
          print('🟡 [AUTH_PROVIDER] New user - creating profile');

          // Logique d'approbation
          ApprovalStatus? approvalStatus;

          if (userType == UserType.client) {
            approvalStatus = ApprovalStatus.approved;
            print('✅ [AUTH_PROVIDER] Client - auto-approved');
          } else if (userType == UserType.restaurant ||
              userType == UserType.delivery) {
            approvalStatus = ApprovalStatus.pending;
            print('⏳ [AUTH_PROVIDER] Restaurant/Delivery - pending approval');
          }

          final fcmToken = await _messaging.getToken();

          _currentUser = UserModel(
            uid: user.uid,
            phoneNumber: user.phoneNumber ?? _currentPhoneNumber!,
            name: name,
            userType: userType,
            createdAt: DateTime.now(),
            approvalStatus: approvalStatus,
            idCardUrl: idCardUrl,
            restaurantName: restaurantName,
            fcmToken: fcmToken,
          );

          // Sauvegarder dans Firestore
          print('🟡 [AUTH_PROVIDER] Saving to Firestore...');
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(_currentUser!.toMap());

          print('✅ [AUTH_PROVIDER] User created in Firestore');
        }

        print('🟢 [AUTH_PROVIDER] Verification complete!');
        return true;
      }

      print('🔴 [AUTH_PROVIDER] No user found');
      return false;
    } on FirebaseAuthException catch (e) {
      print('🔴 [AUTH_PROVIDER] FirebaseAuth Error: ${e.code} - ${e.message}');

      // ✅ MÊME EN CAS D'ERREUR, VÉRIFIER SI L'UTILISATEUR EST CONNECTÉ
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print(
            '🟡 [AUTH_PROVIDER] Error but user is signed in: ${currentUser.uid}');
        // Continuer avec l'utilisateur actuel
        try {
          final userDoc =
              await _firestore.collection('users').doc(currentUser.uid).get();

          if (!userDoc.exists) {
            // Créer le profil
            ApprovalStatus? approvalStatus;
            if (userType == UserType.client) {
              approvalStatus = ApprovalStatus.approved;
            } else {
              approvalStatus = ApprovalStatus.pending;
            }

            final fcmToken = await _messaging.getToken();

            _currentUser = UserModel(
              uid: currentUser.uid,
              phoneNumber: currentUser.phoneNumber ?? _currentPhoneNumber!,
              name: name,
              userType: userType,
              createdAt: DateTime.now(),
              approvalStatus: approvalStatus,
              idCardUrl: idCardUrl,
              restaurantName: restaurantName,
              fcmToken: fcmToken,
            );

            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .set(_currentUser!.toMap());

            print('✅ [AUTH_PROVIDER] User created despite error');
            return true;
          }
        } catch (firestoreError) {
          print('🔴 [AUTH_PROVIDER] Firestore error: $firestoreError');
        }
      }

      throw Exception(e.message ?? 'Erreur de vérification');
    } catch (e) {
      print('🔴 [AUTH_PROVIDER] Error verifying: $e');

      // ✅ DERNIER RECOURS: VÉRIFIER SI L'UTILISATEUR EST QUAND MÊME CONNECTÉ
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print(
            '🟡 [AUTH_PROVIDER] Generic error but user signed in: ${currentUser.uid}');
        return true;
      }

      rethrow;
    }
  }

  Future<void> completeProfile({
    required String name,
    required UserType userType,
    String? idCardUrl,
    String? restaurantName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Non authentifié');

    ApprovalStatus approvalStatus = userType == UserType.client
        ? ApprovalStatus.approved
        : ApprovalStatus.pending;

    final fcmToken = await _messaging.getToken();

    _currentUser = UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? _currentPhoneNumber!,
      name: name,
      userType: userType,
      createdAt: DateTime.now(),
      approvalStatus: approvalStatus,
      idCardUrl: idCardUrl,
      restaurantName: restaurantName,
      fcmToken: fcmToken,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(_currentUser!.toMap());
    notifyListeners();
  }

  // Renvoyer le code
  Future<void> resendPhoneOTP(
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    if (_currentPhoneNumber == null) {
      onError('Aucun numéro de téléphone');
      return;
    }

    await sendPhoneOTP(_currentPhoneNumber!, onSuccess, onError);
  }

  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      print('🔍 [AUTH_PROVIDER] Searching for user with phone: $phoneNumber');

      final query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        print('✅ [AUTH_PROVIDER] User found:');
        print('   - UserType: ${data['userType']}');

        return UserModel.fromMap(data);
      } else {
        print('🆕 [AUTH_PROVIDER] No user found');
        return null;
      }
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _currentPhoneNumber = null;
    _verificationId = null;
    notifyListeners();
    await _auth.signOut();
  }

  Future<void> loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _currentUser = UserModel.fromMap(userDoc.data()!);
          notifyListeners();
        }
      } catch (e) {
        print('Error loading user: $e');
      }
    }
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user: $e');
      return false;
    }
  }
}
