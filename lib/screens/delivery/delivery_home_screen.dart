// lib/screens/delivery/delivery_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliveryPerson),
        backgroundColor: const Color(0xFFFF5722),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.delivery_dining,
                size: 100,
                color: Color(0xFFFF5722),
              ),
              const SizedBox(height: 20),
              Text(
                'Espace Livreur',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),

              // Availability Toggle
              Card(
                child: SwitchListTile(
                  title: Text(
                    _isAvailable ? 'Disponible' : 'Indisponible',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _isAvailable
                        ? 'Vous pouvez recevoir des commandes'
                        : 'Activez pour recevoir des commandes',
                  ),
                  value: _isAvailable,
                  activeColor: const Color(0xFFFF5722),
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                      if (_isAvailable) {
                        locationProvider.startTracking();
                      } else {
                        locationProvider.stopTracking();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Current Location
              if (locationProvider.currentPosition != null)
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.location_on, color: Color(0xFFFF5722)),
                    title: const Text('Position actuelle'),
                    subtitle: Text(
                      'Lat: ${locationProvider.currentPosition!.latitude.toStringAsFixed(4)}\n'
                      'Lng: ${locationProvider.currentPosition!.longitude.toStringAsFixed(4)}',
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Orders count placeholder
              Text(
                l10n.orders,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
