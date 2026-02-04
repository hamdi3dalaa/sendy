// lib/screens/auth/phone_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'otp_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  UserType _selectedUserType = UserType.client;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              l10n.welcome,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Text(l10n.selectUserType, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            _buildUserTypeSelector(l10n),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                prefixText: '+33 ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyPhone,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.verifyPhone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<UserType>(
            title: Text(l10n.client),
            value: UserType.client,
            groupValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value!),
          ),
        ),
        Expanded(
          child: RadioListTile<UserType>(
            title: Text(l10n.deliveryPerson),
            value: UserType.delivery,
            groupValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value!),
          ),
        ),
        Expanded(
          child: RadioListTile<UserType>(
            title: Text(l10n.restaurant),
            value: UserType.restaurant,
            groupValue: _selectedUserType,
            onChanged: (value) => setState(() => _selectedUserType = value!),
          ),
        ),
      ],
    );
  }

  void _verifyPhone() {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNumber = '+33${_phoneController.text}';

    authProvider.verifyPhoneNumber(
      phoneNumber,
      (verificationId) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              phoneNumber: phoneNumber,
              userType: _selectedUserType,
            ),
          ),
        );
      },
      (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language / اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false)
                    .changeLanguage('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('العربية'),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false)
                    .changeLanguage('ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
