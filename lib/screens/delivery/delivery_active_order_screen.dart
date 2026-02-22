// lib/screens/delivery/delivery_active_order_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class DeliveryActiveOrderScreen extends StatefulWidget {
  final OrderModel order;

  const DeliveryActiveOrderScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<DeliveryActiveOrderScreen> createState() =>
      _DeliveryActiveOrderScreenState();
}

class _DeliveryActiveOrderScreenState extends State<DeliveryActiveOrderScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _orderSubscription;

  LatLng? _currentLatLng;
  OrderStatus _currentStatus = OrderStatus.inProgress;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _setupMarkers();
    _startLocationTracking();
    _listenToOrderUpdates();
  }

  void _setupMarkers() {
    final restaurantLoc = widget.order.restaurantLocation;
    final deliveryLoc = widget.order.deliveryLocation;

    if (restaurantLoc.isNotEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: LatLng(
            (restaurantLoc['latitude'] as num).toDouble(),
            (restaurantLoc['longitude'] as num).toDouble(),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Restaurant'),
        ),
      );
    }

    if (deliveryLoc.isNotEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            (deliveryLoc['latitude'] as num).toDouble(),
            (deliveryLoc['longitude'] as num).toDouble(),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Client'),
        ),
      );
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen(
      (Position position) {
        final newLatLng = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLatLng = newLatLng;
          _updateMyMarker(newLatLng);
          _updatePolyline(newLatLng);
        });

        // Push location to Firestore
        context.read<OrderProvider>().updateDeliveryLocation(
          widget.order.orderId,
          {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        );

        _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );
  }

  void _listenToOrderUpdates() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final statusIndex = data['status'] as int?;

        if (statusIndex != null && statusIndex < OrderStatus.values.length) {
          setState(() {
            _currentStatus = OrderStatus.values[statusIndex];
          });

          // If order was cancelled or delivered externally, go back
          if (_currentStatus == OrderStatus.cancelled ||
              _currentStatus == OrderStatus.delivered) {
            if (mounted) {
              Navigator.pop(context);
            }
          }
        }
      }
    });
  }

  void _updateMyMarker(LatLng position) {
    _markers.removeWhere((m) => m.markerId.value == 'my_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('my_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Ma position'),
      ),
    );
  }

  void _updatePolyline(LatLng myPos) {
    final deliveryLoc = widget.order.deliveryLocation;
    if (deliveryLoc.isEmpty) return;

    final destinationLatLng = LatLng(
      (deliveryLoc['latitude'] as num).toDouble(),
      (deliveryLoc['longitude'] as num).toDouble(),
    );

    _polylines = {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: [myPos, destinationLatLng],
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  double _haversineDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371.0;
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

  int _calculateEtaMinutes() {
    if (_currentLatLng == null) return 0;

    final deliveryLoc = widget.order.deliveryLocation;
    if (deliveryLoc.isEmpty) return 0;

    final destination = LatLng(
      (deliveryLoc['latitude'] as num).toDouble(),
      (deliveryLoc['longitude'] as num).toDouble(),
    );

    final distanceKm = _haversineDistance(_currentLatLng!, destination);
    final timeHours = distanceKm / 30.0;
    final timeMinutes = (timeHours * 60).ceil();
    return timeMinutes < 1 ? 1 : timeMinutes;
  }

  Future<void> _completeDelivery() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelivery),
        content: Text(l10n.confirmDeliveryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n.markAsDelivered),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCompleting = true);

    try {
      await context.read<OrderProvider>().completeOrder(widget.order.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deliveryCompleted),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callClient() async {
    final phone = widget.order.clientPhone;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final restaurantLoc = widget.order.restaurantLocation;

    LatLng initialTarget;
    if (_currentLatLng != null) {
      initialTarget = _currentLatLng!;
    } else if (restaurantLoc.isNotEmpty) {
      initialTarget = LatLng(
        (restaurantLoc['latitude'] as num).toDouble(),
        (restaurantLoc['longitude'] as num).toDouble(),
      );
    } else {
      initialTarget = const LatLng(33.5731, -7.5898); // Default: Casablanca
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeDelivery),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
      ),
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
            padding: const EdgeInsets.only(bottom: 220),
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          _buildBottomPanel(context, l10n),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, AppLocalizations l10n) {
    final etaMinutes = _calculateEtaMinutes();

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 12),

            // Order info row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delivery_dining,
                      color: Color(0xFFFF5722), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.orderNumber} #${widget.order.orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (widget.order.clientName != null)
                        Text(
                          widget.order.clientName!,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      if (_currentLatLng != null)
                        Text(
                          l10n.arrivingIn(etaMinutes.toString()),
                          style:
                              TextStyle(color: Colors.green[700], fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.order.deliveryFee.toStringAsFixed(0)} ${l10n.dhs}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Delivery address
            if (widget.order.deliveryAddress != null &&
                widget.order.deliveryAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.red[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.order.deliveryAddress!,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Call client button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callClient,
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(l10n.callClient),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5722),
                      side: const BorderSide(color: Color(0xFFFF5722)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Complete delivery button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isCompleting ? null : _completeDelivery,
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 20),
                    label: Text(l10n.markAsDelivered),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _orderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
