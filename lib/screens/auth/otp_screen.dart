// lib/screens/auth/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../main.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final UserType userType;
  final bool isExistingUser;

  const OTPScreen({
    Key? key,
    required this.phoneNumber,
    required this.userType,
    this.isExistingUser = false,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  final TextEditingController _restaurantNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _idCardImage;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _showRegistrationFields = false;
  bool _otpVerified = false;
  bool _isGettingLocation = false;
  Map<String, dynamic>? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_otpVerified ? 'Créer un compte' : l10n.verify),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === STEP 1: OTP VERIFICATION ===
            if (!_otpVerified) ...[
              const Icon(Icons.sms, size: 80, color: Color(0xFFFF5722)),
              const SizedBox(height: 20),
              Text(
                l10n.enterOTP,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Code envoyé au ${widget.phoneNumber}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPBox(index)),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        l10n.verify,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _resendCode,
                icon: const Icon(Icons.refresh, color: Color(0xFFFF5722)),
                label: const Text(
                  'Renvoyer le code',
                  style: TextStyle(color: Color(0xFFFF5722)),
                ),
              ),
            ],

            // === STEP 2: REGISTRATION (only for new users) ===
            if (_otpVerified && _showRegistrationFields) ...[
              const Icon(Icons.person_add, size: 80, color: Color(0xFFFF5722)),
              const SizedBox(height: 20),
              const Text(
                'Complétez votre profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Nom complet
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  hintText: 'Mohamed Ali',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // Restaurant Name
              if (widget.userType == UserType.restaurant) ...[
                TextField(
                  controller: _restaurantNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du restaurant *',
                    hintText: 'Pizza Royale',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                // Restaurant Address
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse du restaurant *',
                    hintText: 'Rue Mohamed V, N°15',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: _isGettingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFFFF5722)),
                            onPressed: _getLocationByGPS,
                            tooltip: 'Utiliser GPS',
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // City
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville *',
                    hintText: 'Casablanca',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),

                // GPS location button
                OutlinedButton.icon(
                  onPressed: _isGettingLocation ? null : _getLocationByGPS,
                  icon: Icon(
                    _selectedLocation != null ? Icons.check_circle : Icons.gps_fixed,
                    color: _selectedLocation != null ? Colors.green : const Color(0xFFFF5722),
                  ),
                  label: Text(
                    _selectedLocation != null
                        ? 'Position GPS capturée ✓'
                        : 'Capturer la position GPS',
                    style: TextStyle(
                      color: _selectedLocation != null ? Colors.green : const Color(0xFFFF5722),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: _selectedLocation != null ? Colors.green : const Color(0xFFFF5722),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ID Card Upload
              if (widget.userType == UserType.delivery ||
                  widget.userType == UserType.restaurant) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _idCardImage != null
                            ? Icons.check_circle
                            : Icons.credit_card,
                        size: 60,
                        color: _idCardImage != null
                            ? Colors.green
                            : const Color(0xFFFF5722),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _idCardImage != null
                            ? 'Carte d\'identité téléchargée ✓'
                            : 'Télécharger la carte d\'identité',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _idCardImage != null
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_idCardImage != null)
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(_idCardImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Caméra'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galerie'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '* Requis pour vérification',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Create Account Button
              ElevatedButton(
                onPressed:
                    (_isLoading || _isUploading) ? null : _completeRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading || _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Créer mon compte',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF5722)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF5722), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _idCardImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }

  Future<String?> _uploadIdCard() async {
    if (_idCardImage == null) return null;

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final fileName = 'id_cards/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      // Add timeout to prevent hanging
      final uploadTask = ref.putFile(_idCardImage!);

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload timeout - vérifiez votre connexion internet');
        },
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('🔴 [OTP_SCREEN] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // STEP 1: Verify OTP only
  Future<void> _verifyOTP() async {
    print('🔵 [OTP_SCREEN] _verifyOTP called');

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le code complet')),
      );
      return;
    }
    print('🔵 [OTP_SCREEN] OTP: $otp');

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyPhoneOTP(
        otp,
        widget.userType,
      );

      if (success && mounted) {
        final user = authProvider.currentUser;

        if (user != null && user.hasName) {
          // Existing user — go home directly
          print('🟢 [OTP_SCREEN] Existing user, going home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connexion réussie!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        } else {
          // New user — show registration fields
          print('🟡 [OTP_SCREEN] New user, showing registration');
          setState(() {
            _otpVerified = true;
            _showRegistrationFields = true;
          });
        }
      } else if (mounted) {
        print('🔴 [OTP_SCREEN] Verification failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code invalide. Réessayez.')),
        );
      }
    } catch (e) {
      print('🔴 [OTP_SCREEN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getLocationByGPS() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission de localisation refusée')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activez la localisation dans les paramètres')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _selectedLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      // Reverse geocode to get address
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((s) => s != null && s.isNotEmpty).join(', ');

          if (mounted) {
            setState(() {
              if (address.isNotEmpty) {
                _addressController.text = address;
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                _cityController.text = place.locality!;
              } else if (place.subAdministrativeArea != null) {
                _cityController.text = place.subAdministrativeArea!;
              }
            });
          }
        }
      } catch (e) {
        print('Geocoding error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position GPS capturée !'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      print('GPS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur GPS: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // STEP 2: Complete registration for new users
  Future<void> _completeRegistration() async {
    print('🔵 [OTP_SCREEN] _completeRegistration called');

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre nom')),
      );
      return;
    }

    // Validate restaurant name
    if (widget.userType == UserType.restaurant &&
        _restaurantNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom du restaurant')),
      );
      return;
    }

    // Validate restaurant address
    if (widget.userType == UserType.restaurant &&
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer l\'adresse du restaurant')),
      );
      return;
    }

    // Validate city
    if (widget.userType == UserType.restaurant &&
        _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer la ville')),
      );
      return;
    }

    // Validate ID card
    if ((widget.userType == UserType.delivery ||
            widget.userType == UserType.restaurant) &&
        _idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez télécharger votre carte d\'identité'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload ID card if needed
      String? idCardUrl;
      if (_idCardImage != null) {
        print('🔵 [OTP_SCREEN] Uploading ID card...');
        idCardUrl = await _uploadIdCard();
        if (idCardUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
        print('🟢 [OTP_SCREEN] ID card uploaded: $idCardUrl');
      }

      // Complete profile
      print('🔵 [OTP_SCREEN] Completing profile...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.completeProfile(
        name: _nameController.text.trim(),
        userType: widget.userType,
        idCardUrl: idCardUrl,
        restaurantName: widget.userType == UserType.restaurant
            ? _restaurantNameController.text.trim()
            : null,
        restaurantAddress: widget.userType == UserType.restaurant
            ? _addressController.text.trim()
            : null,
        city: widget.userType == UserType.restaurant
            ? _cityController.text.trim()
            : null,
        location: _selectedLocation,
      );

      if (mounted) {
        print('🟢 [OTP_SCREEN] Profile completed!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Compte créé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      print('🔴 [OTP_SCREEN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resendCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    authProvider.resendPhoneOTP(
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Code renvoyé!')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _nameController.dispose();
    _restaurantNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
