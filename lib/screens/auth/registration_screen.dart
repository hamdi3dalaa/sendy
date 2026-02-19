// lib/screens/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  UserType? _selectedType;
  File? _idCardImage;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isGettingLocation = false;
  Map<String, dynamic>? _selectedLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _restaurantNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
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
        setState(() => _idCardImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<String?> _uploadIdCard() async {
    if (_idCardImage == null) return null;

    setState(() => _isUploading = true);
    try {
      final fileName = 'id_cards/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(_idCardImage!);
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload timeout');
        },
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
              const SnackBar(content: Text('Permission de localisation refusee')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activez la localisation dans les parametres')),
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

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = [place.street, place.subLocality, place.locality]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          if (mounted) {
            setState(() {
              if (address.isNotEmpty) _addressController.text = address;
              if (place.locality != null && place.locality!.isNotEmpty) {
                _cityController.text = place.locality!;
              } else if (place.subAdministrativeArea != null) {
                _cityController.text = place.subAdministrativeArea!;
              }
            });
          }
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position GPS capturee !'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur GPS: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submitRegistration() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un type de compte')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre nom')),
      );
      return;
    }
    if (_selectedType == UserType.restaurant) {
      if (_restaurantNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer le nom du restaurant')),
        );
        return;
      }
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer l\'adresse du restaurant')),
        );
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer la ville')),
        );
        return;
      }
    }
    setState(() => _isLoading = true);

    try {
      // Try to upload ID card, but don't block registration if it fails
      String? idCardUrl;
      if (_idCardImage != null) {
        idCardUrl = await _uploadIdCard();
        // If upload fails, continue with registration (ID can be uploaded later)
        if (idCardUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La carte d\'identite sera demandee plus tard'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final authProvider = context.read<AuthProvider>();
      await authProvider.completeProfile(
        name: _nameController.text.trim(),
        userType: _selectedType!,
        idCardUrl: idCardUrl,
        restaurantName: _selectedType == UserType.restaurant
            ? _restaurantNameController.text.trim()
            : null,
        restaurantAddress: _selectedType == UserType.restaurant
            ? _addressController.text.trim()
            : null,
        city: _selectedType == UserType.restaurant
            ? _cityController.text.trim()
            : null,
        location: _selectedLocation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte cree avec succes !'),
            backgroundColor: Colors.green,
          ),
        );
        // AuthWrapper will automatically route to the correct screen
        // after completeProfile sets _currentUser and notifies listeners
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creer un compte'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add, size: 60, color: Color(0xFFFF5722)),
            const SizedBox(height: 16),
            const Text(
              'Completez votre inscription',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // === TYPE SELECTION ===
            const Text(
              'Type de compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Approval warning
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les comptes Restaurant et Livreur necessitent une approbation par l\'administration.',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeOption(
              type: UserType.client,
              icon: Icons.person,
              title: 'Client',
              subtitle: 'Commander de la nourriture',
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildTypeOption(
              type: UserType.delivery,
              icon: Icons.delivery_dining,
              title: 'Livreur',
              subtitle: 'Livrer des commandes',
              color: Colors.orange,
              needsApproval: true,
            ),
            const SizedBox(height: 8),
            _buildTypeOption(
              type: UserType.restaurant,
              icon: Icons.restaurant,
              title: 'Restaurant',
              subtitle: 'Gerer votre restaurant',
              color: Colors.green,
              needsApproval: true,
            ),

            const SizedBox(height: 24),

            // === PROFILE FIELDS (shown after type selection) ===
            if (_selectedType != null) ...[
              // Name field
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

              // Restaurant-specific fields
              if (_selectedType == UserType.restaurant) ...[
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
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse du restaurant *',
                    hintText: 'Rue Mohamed V, N 15',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: _isGettingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFFFF5722)),
                            onPressed: _getLocationByGPS,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isGettingLocation ? null : _getLocationByGPS,
                  icon: Icon(
                    _selectedLocation != null ? Icons.check_circle : Icons.gps_fixed,
                    color: _selectedLocation != null ? Colors.green : const Color(0xFFFF5722),
                  ),
                  label: Text(
                    _selectedLocation != null
                        ? 'Position GPS capturee'
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

              // ID Card upload (for delivery and restaurant)
              if (_selectedType == UserType.delivery ||
                  _selectedType == UserType.restaurant) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _idCardImage != null ? Icons.check_circle : Icons.credit_card,
                        size: 50,
                        color: _idCardImage != null ? Colors.green : const Color(0xFFFF5722),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _idCardImage != null
                            ? 'Carte d\'identite telechargee'
                            : 'Telecharger la carte d\'identite *',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _idCardImage != null ? Colors.green : Colors.black,
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
                            label: const Text('Camera'),
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
                const SizedBox(height: 20),
              ],

              // Submit button
              ElevatedButton(
                onPressed: (_isLoading || _isUploading) ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: (_isLoading || _isUploading)
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Creer mon compte',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required UserType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool needsApproval = false,
  }) {
    final isSelected = _selectedType == type;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black,
                        )),
                    Text(subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    if (needsApproval) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              size: 13, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Approbation requise',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 28)
              else
                Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
