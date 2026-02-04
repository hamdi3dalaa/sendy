// lib/screens/map/tracking_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import 'dart:async';

class TrackingMapScreen extends StatefulWidget {
  final OrderModel order;
  final bool isDeliveryPerson;

  const TrackingMapScreen({
    Key? key,
    required this.order,
    this.isDeliveryPerson = false,
  }) : super(key: key);

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _listenToOrderUpdates();
  }

  void _setupMarkers() {
    final restaurantLoc = widget.order.restaurantLocation;
    final deliveryLoc = widget.order.deliveryLocation;

    _markers.add(
      Marker(
        markerId: const MarkerId('restaurant'),
        position: LatLng(
          restaurantLoc['latitude'],
          restaurantLoc['longitude'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          deliveryLoc['latitude'],
          deliveryLoc['longitude'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
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
        final currentLoc = data['currentDeliveryLocation'];

        if (currentLoc != null) {
          setState(() {
            _markers.removeWhere((m) => m.markerId.value == 'delivery_person');
            _markers.add(
              Marker(
                markerId: const MarkerId('delivery_person'),
                position: LatLng(
                  currentLoc['latitude'],
                  currentLoc['longitude'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                infoWindow: const InfoWindow(title: 'Delivery Person'),
              ),
            );
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(currentLoc['latitude'], currentLoc['longitude']),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantLoc = widget.order.restaurantLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            restaurantLoc['latitude'],
            restaurantLoc['longitude'],
          ),
          zoom: 14,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
