// lib/screens/waiting_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class WaitingApprovalScreen extends StatelessWidget {
  final UserType userType;
  final bool isRejected;

  const WaitingApprovalScreen({
    Key? key,
    required this.userType,
    this.isRejected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: const Color(0xFFFF5722),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isRejected
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.cancel : Icons.access_time,
                  size: 100,
                  color: isRejected ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                isRejected ? l10n.rejected : l10n.waitingApproval,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isRejected ? Colors.red : Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Message
              Text(
                isRejected
                    ? _getRejectedMessage(userType, l10n)
                    : _getPendingMessage(userType, l10n),
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Loading or Action Button
              if (!isRejected) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Vérification en cours...',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => authProvider.signOut(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer avec un autre compte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Contact support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Contactez le support: support@sendy.com'),
                      ),
                    );
                  },
                  child: const Text('Contacter le support'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPendingMessage(UserType type, AppLocalizations l10n) {
    if (type == UserType.delivery) {
      return 'Votre demande d\'inscription en tant que livreur est en cours d\'examen. '
          'Nous vérifierons votre carte d\'identité et vous informerons bientôt.\n\n'
          'Cela peut prendre 24 à 48 heures.';
    } else {
      return 'Votre demande d\'inscription en tant que restaurant est en cours d\'examen. '
          'Nous vérifierons vos documents et vous informerons bientôt.\n\n'
          'Cela peut prendre 24 à 48 heures.';
    }
  }

  String _getRejectedMessage(UserType type, AppLocalizations l10n) {
    if (type == UserType.delivery) {
      return 'Votre demande d\'inscription en tant que livreur a été refusée. '
          'Cela peut être dû à des documents incomplets ou invalides.\n\n'
          'Veuillez contacter le support pour plus d\'informations.';
    } else {
      return 'Votre demande d\'inscription en tant que restaurant a été refusée. '
          'Cela peut être dû à des documents incomplets ou invalides.\n\n'
          'Veuillez contacter le support pour plus d\'informations.';
    }
  }
}
