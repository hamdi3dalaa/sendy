// lib/screens/map/tracking_map_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../models/order_model.dart';

class TrackingMapScreen extends StatefulWidget {
  final OrderModel order;

  const TrackingMapScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription? _orderSubscription;

  LatLng? _deliveryPersonLatLng;
  OrderStatus _currentStatus = OrderStatus.pending;
  String? _deliveryPersonName;
  String? _deliveryPersonPhone;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _setupMarkers();
    _listenToOrderUpdates();
    _loadDeliveryPersonInfo();
  }

  Future<void> _loadDeliveryPersonInfo() async {
    final deliveryId = widget.order.deliveryPersonId;
    if (deliveryId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(deliveryId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _deliveryPersonName = data['name'] as String?;
          _deliveryPersonPhone = data['phone'] as String?;
        });
      }
    } catch (e) {
      print('Error loading delivery person info: $e');
    }
  }

  Future<void> _callDeliveryPerson() async {
    if (_deliveryPersonPhone != null && _deliveryPersonPhone!.isNotEmpty) {
      final uri = Uri.parse('tel:$_deliveryPersonPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  /// Safely parse a LatLng from a location map. Returns null if data is missing.
  LatLng? _parseLatLng(Map<String, dynamic> loc) {
    final lat = loc['latitude'];
    final lng = loc['longitude'];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  void _setupMarkers() {
    final restaurantLoc = widget.order.restaurantLocation;
    final deliveryLoc = widget.order.deliveryLocation;

    final restaurantLatLng = _parseLatLng(restaurantLoc);
    if (restaurantLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: restaurantLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Restaurant'),
        ),
      );
    }

    final destinationLatLng = _parseLatLng(deliveryLoc);
    if (destinationLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Add initial delivery person marker if available
    final currentLoc = widget.order.currentDeliveryLocation;
    if (currentLoc != null) {
      final currentLatLng = _parseLatLng(currentLoc);
      if (currentLatLng != null) {
        _deliveryPersonLatLng = currentLatLng;
        _updateDeliveryPersonMarker(currentLatLng);
      }
    }
  }

  void _listenToOrderUpdates() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final currentLoc = data['currentDeliveryLocation'];
        final statusIndex = data['status'] as int?;

        setState(() {
          if (statusIndex != null && statusIndex < OrderStatus.values.length) {
            _currentStatus = OrderStatus.values[statusIndex];
          }
        });

        // Auto-close when delivered
        if (_currentStatus == OrderStatus.delivered && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).orderDelivered),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          return;
        }

        if (currentLoc != null) {
          final newLatLng = LatLng(
            (currentLoc['latitude'] as num).toDouble(),
            (currentLoc['longitude'] as num).toDouble(),
          );

          setState(() {
            _deliveryPersonLatLng = newLatLng;
            _updateDeliveryPersonMarker(newLatLng);
            _updatePolyline(newLatLng);
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(newLatLng),
          );
        }
      }
    });
  }

  void _updateDeliveryPersonMarker(LatLng position) {
    _markers.removeWhere((m) => m.markerId.value == 'delivery_person');
    _markers.add(
      Marker(
        markerId: const MarkerId('delivery_person'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Delivery Person'),
      ),
    );
  }

  void _updatePolyline(LatLng deliveryPersonPos) {
    final destinationLatLng = _parseLatLng(widget.order.deliveryLocation);
    if (destinationLatLng == null) return;

    _polylines = {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: [deliveryPersonPos, destinationLatLng],
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  /// Calculates the haversine distance between two points in kilometers.
  double _haversineDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371.0; // km
    final dLat = _degToRad(to.latitude - from.latitude);
    final dLng = _degToRad(to.longitude - from.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(from.latitude)) *
            cos(_degToRad(to.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  /// Returns ETA in minutes based on 30 km/h average speed.
  int _calculateEtaMinutes() {
    if (_deliveryPersonLatLng == null) return 0;

    final destination = _parseLatLng(widget.order.deliveryLocation);
    if (destination == null) return 0;

    final distanceKm = _haversineDistance(_deliveryPersonLatLng!, destination);
    final timeHours = distanceKm / 30.0;
    final timeMinutes = (timeHours * 60).ceil();
    return timeMinutes < 1 ? 1 : timeMinutes;
  }

  int _statusToStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.inProgress:
        return 3; // On the Way
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initialTarget = _parseLatLng(widget.order.restaurantLocation)
        ?? _parseLatLng(widget.order.deliveryLocation)
        ?? const LatLng(33.5731, -7.5898); // Default: Casablanca

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trackOrder)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            padding: const EdgeInsets.only(bottom: 280),
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          _buildBottomSheet(context, l10n),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, AppLocalizations l10n) {
    final etaMinutes = _calculateEtaMinutes();
    final currentStep = _statusToStepIndex(_currentStatus);

    final stepLabels = [
      l10n.orderPlaced,
      l10n.orderAccepted,
      l10n.orderPickedUp,
      l10n.onTheWay,
      l10n.orderDelivered,
    ];

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order status step indicator
            _buildStepIndicator(stepLabels, currentStep),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 12),

            // Delivery person info
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _deliveryPersonName ?? l10n.deliveryPerson,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_deliveryPersonLatLng != null)
                        Text(
                          l10n.arrivingIn(etaMinutes.toString()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Call delivery person button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deliveryPersonPhone != null
                    ? _callDeliveryPerson
                    : null,
                icon: const Icon(Icons.phone),
                label: Text(l10n.callDelivery),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(List<String> labels, int currentStep) {
    return Row(
      children: List.generate(labels.length, (index) {
        final isCompleted = index <= currentStep;
        final isLast = index == labels.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : Colors.grey[300],
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCompleted
                            ? Colors.green[800]
                            : Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: index < currentStep
                        ? Colors.green
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
