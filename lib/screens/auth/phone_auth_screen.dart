// lib/screens/auth/phone_auth_screen.dart
// COMPLETE FIXED VERSION - No l10n dependency

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

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
        print('🆕 New user - showing type selection');
        if (mounted) {
          _showUserTypeSelection(code);
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

  void _showUserTypeSelection(String verificationCode) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserTypeSelectionSheet(
        phoneNumber: fullPhoneNumber,
        verificationCode: verificationCode,
      ),
    );
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
                  const SizedBox(height: 50),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                      _getUserTypeIcon(_existingUser!.userType),
                                      color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Connexion en tant que: ${_getUserTypeText(_existingUser!.userType)}',
                                      style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontWeight: FontWeight.w500),
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

class _UserTypeSelectionSheet extends StatefulWidget {
  final String phoneNumber;
  final String verificationCode;

  const _UserTypeSelectionSheet({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  State<_UserTypeSelectionSheet> createState() =>
      _UserTypeSelectionSheetState();
}

class _UserTypeSelectionSheetState extends State<_UserTypeSelectionSheet> {
  bool _isLoading = false;

  Future<void> _selectUserType(UserType userType) async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.verifyPhoneOTP(
        widget.verificationCode,
        userType,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choisissez votre type de compte',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildUserTypeCard(
            icon: Icons.person,
            title: 'Client',
            subtitle: 'Commander de la nourriture',
            color: Colors.blue,
            onTap: () => _selectUserType(UserType.client),
          ),
          const SizedBox(height: 12),
          _buildUserTypeCard(
            icon: Icons.delivery_dining,
            title: 'Livreur',
            subtitle: 'Livrer des commandes',
            color: Colors.orange,
            onTap: () => _selectUserType(UserType.delivery),
          ),
          const SizedBox(height: 12),
          _buildUserTypeCard(
            icon: Icons.restaurant,
            title: 'Restaurant',
            subtitle: 'Gérer votre restaurant',
            color: Colors.green,
            onTap: () => _selectUserType(UserType.restaurant),
          ),
          const SizedBox(height: 24),
          if (_isLoading) const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
