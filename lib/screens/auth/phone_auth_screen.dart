// lib/screens/auth/phone_auth_screen.dart
// COMPLETE FIXED VERSION - No l10n dependency

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'registration_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _existingUser;

  String _selectedCountryCode = '+212';
  String _selectedCountryFlag = '🇲🇦';
  String _selectedCountryName = 'Maroc';

  final List<Map<String, String>> _countries = [
    {'name': 'Maroc', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Algérie', 'code': '+213', 'flag': '🇩🇿'},
    {'name': 'Tunisie', 'code': '+216', 'flag': '🇹🇳'},
    {'name': 'Belgique', 'code': '+32', 'flag': '🇧🇪'},
    {'name': 'Suisse', 'code': '+41', 'flag': '🇨🇭'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'États-Unis', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'Royaume-Uni', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Espagne', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Italie', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Allemagne', 'code': '+49', 'flag': '🇩🇪'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sélectionnez votre pays',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  return ListTile(
                    leading: Text(country['flag']!,
                        style: const TextStyle(fontSize: 28)),
                    title: Text(country['name']!),
                    trailing: Text(
                      country['code']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722)),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                        _selectedCountryName = country['name']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get fullPhoneNumber =>
      '$_selectedCountryCode${_phoneController.text.trim()}';

  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(
          () => _errorMessage = 'Veuillez entrer votre numéro de téléphone');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullPhone = fullPhoneNumber;
    final authProvider = context.read<AuthProvider>();

    print('🔍 Checking if user exists: $fullPhone');
    final existingUser = await authProvider.getUserByPhoneNumber(fullPhone);

    if (existingUser != null) {
      print('✅ User exists! Type: ${existingUser.userType}');
      setState(() => _existingUser = existingUser);
    } else {
      print('🆕 New user');
      setState(() => _existingUser = null);
    }

    await authProvider.sendPhoneOTP(
      fullPhone,
      (message) {
        if (mounted) {
          setState(() {
            _codeSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _otpController.text.trim();
    final authProvider = context.read<AuthProvider>();

    try {
      if (_existingUser != null) {
        // Existing user: verify OTP and login with detected type
        print('✅ Logging in existing user');
        final success = await authProvider.verifyPhoneOTP(
          code,
          _existingUser!.userType,
          name: _existingUser!.name,
        );
        if (success && mounted) {
          print('✅ Login successful');
        }
      } else {
        // New user: sign in with OTP, then navigate to registration
        print('🆕 New user - signing in and going to registration');
        final success = await authProvider.signInWithOTP(code);
        if (success && mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RegistrationScreen(),
            ),
          );
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📱 [PHONE_AUTH] Building PhoneAuthScreen');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delivery_dining,
                        size: 60, color: Color(0xFFFF5722)),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'SENDY',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Livraison rapide et fiable',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Language Toggle
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final isArabic = authProvider.locale.languageCode == 'ar';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => authProvider.changeLanguage('fr'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !isArabic ? Colors.white : Colors.white.withOpacity(0.3),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Text(
                                '🇫🇷 Français',
                                style: TextStyle(
                                  fontWeight: !isArabic ? FontWeight.bold : FontWeight.normal,
                                  color: !isArabic ? const Color(0xFFFF5722) : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => authProvider.changeLanguage('ar'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isArabic ? Colors.white : Colors.white.withOpacity(0.3),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Text(
                                '🇲🇦 العربية',
                                style: TextStyle(
                                  fontWeight: isArabic ? FontWeight.bold : FontWeight.normal,
                                  color: isArabic ? const Color(0xFFFF5722) : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: _codeSent ? null : _showCountryPicker,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(_selectedCountryFlag,
                                          style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 8),
                                      Text(_selectedCountryCode,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_drop_down,
                                          color: _codeSent
                                              ? Colors.grey
                                              : Colors.black),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  enabled: !_codeSent,
                                  decoration: InputDecoration(
                                    labelText: 'Numéro de téléphone',
                                    hintText: '612345678',
                                    prefixIcon: const Icon(Icons.phone),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Numéro complet: $fullPhoneNumber',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_codeSent) ...[
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Code de vérification',
                                hintText: '123456',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (_existingUser != null && _codeSent) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Compte detecte !',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getUserTypeIcon(_existingUser!.userType),
                                          color: _getUserTypeColor(_existingUser!.userType),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getUserTypeText(_existingUser!.userType),
                                          style: TextStyle(
                                            color: _getUserTypeColor(_existingUser!.userType),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_existingUser!.name != null && _existingUser!.name!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _existingUser!.name!,
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Entrez le code pour vous connecter',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700)),
                            ),
                            const SizedBox(height: 20),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_codeSent ? _verifyOTP : _sendOTP),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _codeSent
                                          ? 'Vérifier le code'
                                          : 'Envoyer le code',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : _sendOTP,
                              child: const Text('Renvoyer le code'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getUserTypeColor(UserType type) {
    switch (type) {
      case UserType.client:
        return Colors.blue;
      case UserType.delivery:
        return Colors.orange;
      case UserType.restaurant:
        return Colors.green;
      case UserType.admin:
        return Colors.purple;
    }
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.client:
        return Icons.person;
      case UserType.delivery:
        return Icons.delivery_dining;
      case UserType.restaurant:
        return Icons.restaurant;
      case UserType.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _getUserTypeText(UserType type) {
    switch (type) {
      case UserType.client:
        return 'Client';
      case UserType.delivery:
        return 'Livreur';
      case UserType.restaurant:
        return 'Restaurant';
      case UserType.admin:
        return 'Administrateur';
    }
  }
}
