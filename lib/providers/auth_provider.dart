// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  UserModel? _currentUser;
  Locale _locale = const Locale('fr');
  String? _verificationId;

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
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> verifyOTP(String smsCode, UserType userType,
      {String? idCardUrl, String? restaurantName}) async {
    try {
      if (_verificationId == null) return false;

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final fcmToken = await _messaging.getToken();

      ApprovalStatus? approvalStatus;
      if (userType == UserType.delivery || userType == UserType.restaurant) {
        approvalStatus = ApprovalStatus.pending;
      }

      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        phoneNumber: userCredential.user!.phoneNumber!,
        userType: userType,
        approvalStatus: approvalStatus,
        idCardUrl: idCardUrl,
        restaurantName: restaurantName,
        fcmToken: fcmToken,
      );

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      _currentUser = newUser;
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
