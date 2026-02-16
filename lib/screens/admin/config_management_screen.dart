import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ConfigManagementScreen extends StatefulWidget {
  const ConfigManagementScreen({Key? key}) : super(key: key);
  @override
  State<ConfigManagementScreen> createState() => _ConfigManagementScreenState();
}

class _ConfigManagementScreenState extends State<ConfigManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// Twilio Config Controllers
  final TextEditingController _accountSidController = TextEditingController();
  final TextEditingController _authTokenController = TextEditingController();
  final TextEditingController _whatsappNumberController =
      TextEditingController();
  final TextEditingController _contentSidController = TextEditingController();
  bool _twilioEnabled = true;
  bool _useContentTemplate = true;
// OTP Config Controllers
  final TextEditingController _otpLengthController = TextEditingController();
  final TextEditingController _expiryMinutesController =
      TextEditingController();
  final TextEditingController _maxAttemptsController = TextEditingController();
  final TextEditingController _cooldownController = TextEditingController();
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      // Charger Twilio Config
      final twilioDoc =
          await _firestore.collection('app_config').doc('twilio_config').get();

      if (twilioDoc.exists) {
        final data = twilioDoc.data()!;
        _accountSidController.text = data['accountSid'] ?? '';
        _authTokenController.text = data['authToken'] ?? '';
        _whatsappNumberController.text = data['whatsappNumber'] ?? '';
        _contentSidController.text = data['contentSid'] ?? '';
        _twilioEnabled = data['enabled'] ?? true;
        _useContentTemplate = data['useContentTemplate'] ?? true;
      }

      // Charger OTP Config
      final otpDoc =
          await _firestore.collection('app_config').doc('otp_config').get();

      if (otpDoc.exists) {
        final data = otpDoc.data()!;
        _otpLengthController.text = data['otpLength'].toString();
        _expiryMinutesController.text = data['expiryMinutes'].toString();
        _maxAttemptsController.text = data['maxAttempts'].toString();
        _cooldownController.text = data['resendCooldownSeconds'].toString();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTwilioConfig() async {
    try {
      await _firestore.collection('app_config').doc('twilio_config').set({
        'accountSid': _accountSidController.text,
        'authToken': _authTokenController.text,
        'whatsappNumber': _whatsappNumberController.text,
        'contentSid': _contentSidController.text,
        'enabled': _twilioEnabled,
        'useContentTemplate': _useContentTemplate,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration Twilio sauvegardée!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveOTPConfig() async {
    try {
      await _firestore.collection('app_config').doc('otp_config').set({
        'otpLength': int.parse(_otpLengthController.text),
        'expiryMinutes': int.parse(_expiryMinutesController.text),
        'maxAttempts': int.parse(_maxAttemptsController.text),
        'resendCooldownSeconds': int.parse(_cooldownController.text),
        'contentVariables': {
          'otpVariable': '1',
          'expiryVariable': '2',
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration OTP sauvegardée!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration App'),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Twilio Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 80,
                          color: Color(0xFF25D366),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Configuration Twilio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _accountSidController,
                      decoration: const InputDecoration(
                        labelText: 'Account SID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _authTokenController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Auth Token',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _whatsappNumberController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number',
                        hintText: 'whatsapp:+14155238886',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentSidController,
                      decoration: const InputDecoration(
                        labelText: 'Content SID (Template WhatsApp)',
                        hintText: 'HXb5b62575e6e4ff6129ad7c8efe1f983e',
                        border: OutlineInputBorder(),
                        helperText: 'Template approuvé par WhatsApp',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Service activé'),
                      value: _twilioEnabled,
                      onChanged: (value) {
                        setState(() => _twilioEnabled = value);
                      },
                      activeColor: Colors.green,
                    ),
                    SwitchListTile(
                      title: const Text('Utiliser Content Template'),
                      subtitle:
                          const Text('Désactiver pour message texte simple'),
                      value: _useContentTemplate,
                      onChanged: (value) {
                        setState(() => _useContentTemplate = value);
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveTwilioConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('Sauvegarder Twilio Config'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // OTP Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lock, color: Color(0xFFFF5722), size: 32),
                        SizedBox(width: 10),
                        Text(
                          'Configuration OTP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpLengthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Longueur du code OTP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _expiryMinutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expiration (minutes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _maxAttemptsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tentatives max',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cooldownController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cooldown renvoi (secondes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveOTPConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('Sauvegarder OTP Config'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accountSidController.dispose();
    _authTokenController.dispose();
    _whatsappNumberController.dispose();
    _contentSidController.dispose();
    _otpLengthController.dispose();
    _expiryMinutesController.dispose();
    _maxAttemptsController.dispose();
    _cooldownController.dispose();
    super.dispose();
  }
}
