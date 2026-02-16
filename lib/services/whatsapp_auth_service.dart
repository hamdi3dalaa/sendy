// lib/services/whatsapp_auth_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhatsAppAuthService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    print('🟨 [WHATSAPP_SERVICE] sendOTP: $phoneNumber');

    try {
      final callable = _functions.httpsCallable('sendWhatsAppOTP');
      final result = await callable.call({'phoneNumber': phoneNumber});

      print('🟨 [WHATSAPP_SERVICE] Result: ${result.data}');

      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'expiryMinutes': result.data['expiryMinutes'] ?? 5,
      };
    } on FirebaseFunctionsException catch (e) {
      print('🔴 [WHATSAPP_SERVICE] Functions Error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Erreur lors de l\'envoi du code');
    } catch (e) {
      print('🔴 [WHATSAPP_SERVICE] Error: $e');
      throw Exception('Erreur lors de l\'envoi du code');
    }
  }

  Future<User?> verifyOTP(String phoneNumber, String code) async {
    print('🟨 [WHATSAPP_SERVICE] verifyOTP: $phoneNumber, code: $code');

    try {
      final callable = _functions.httpsCallable('verifyWhatsAppOTP');
      final result = await callable.call({
        'phoneNumber': phoneNumber,
        'code': code,
      });

      print('🟨 [WHATSAPP_SERVICE] Verify result: ${result.data}');

      if (result.data['success']) {
        // Connexion anonyme (l'UID sera géré dans Firestore)
        final userCredential = await _auth.signInAnonymously();
        print('🟢 [WHATSAPP_SERVICE] Signed in: ${userCredential.user?.uid}');
        return userCredential.user;
      }

      return null;
    } on FirebaseFunctionsException catch (e) {
      print('🔴 [WHATSAPP_SERVICE] Functions Error: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'invalid-argument':
          errorMessage = 'Code incorrect';
          break;
        case 'deadline-exceeded':
          errorMessage = 'Code expiré';
          break;
        case 'resource-exhausted':
          errorMessage = 'Trop de tentatives';
          break;
        case 'already-exists':
          errorMessage = 'Code déjà utilisé';
          break;
        case 'not-found':
          errorMessage = 'Code invalide';
          break;
        default:
          errorMessage = e.message ?? 'Erreur de vérification';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('🔴 [WHATSAPP_SERVICE] Error: $e');
      throw Exception('Erreur de vérification');
    }
  }

  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    try {
      final callable = _functions.httpsCallable('resendWhatsAppOTP');
      final result = await callable.call({'phoneNumber': phoneNumber});

      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
      };
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception(e.message ?? 'Attendez avant de renvoyer le code');
      }
      throw Exception(e.message ?? 'Erreur lors du renvoi du code');
    } catch (e) {
      throw Exception('Erreur lors du renvoi du code');
    }
  }
}
