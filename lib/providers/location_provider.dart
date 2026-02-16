// lib/providers/location_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isInitializing = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  Future<void> initializeLocation() async {
    if (_isInitializing) return;

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error =
            'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Step 2: Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Permission de localisation refusée';
          _isInitializing = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error =
            'Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.';
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Step 3: Get current position with timeout and error handling
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('La localisation a pris trop de temps');
        },
      );

      print(
          'Location obtained: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } on TimeoutException catch (e) {
      _error = 'Impossible d\'obtenir la localisation (timeout)';
      print('Location timeout: $e');
    } on LocationServiceDisabledException catch (e) {
      _error = 'Les services de localisation sont désactivés';
      print('Location service disabled: $e');
    } on PermissionDeniedException catch (e) {
      _error = 'Permission de localisation refusée';
      print('Permission denied: $e');
    } catch (e) {
      _error = 'Erreur lors de l\'obtention de la localisation: $e';
      print('Location error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void startTracking() {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen(
      (Position position) {
        _currentPosition = position;
        print('Position updated: ${position.latitude}, ${position.longitude}');
        notifyListeners();
      },
      onError: (error) {
        _error = 'Erreur de suivi: $error';
        print('Tracking error: $error');
        notifyListeners();
      },
    );
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    print('Location tracking stopped');
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
