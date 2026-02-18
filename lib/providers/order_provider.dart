// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<OrderModel> _orders = [];
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user orders (for client order history)
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 [ORDER_PROVIDER] Loading orders for user: $userId');

      final snapshot = await _firestore
          .collection('orders')
          .where('clientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 15));

      print('🔵 [ORDER_PROVIDER] Found ${snapshot.docs.length} orders');

      _userOrders =
          snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();

      print('✅ [ORDER_PROVIDER] Loaded ${_userOrders.length} orders');
    } on TimeoutException catch (e) {
      _error = 'Timeout: $e';
      print('❌ [ORDER_PROVIDER] Timeout: $e');
      _userOrders = [];
    } catch (e) {
      _error = 'Erreur: $e';
      print('❌ [ORDER_PROVIDER] Error: $e');
      _userOrders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<OrderModel>> getOrdersForUser(String userId, UserType userType) {
    Query query;

    switch (userType) {
      case UserType.client:
        query = _firestore
            .collection('orders')
            .where('clientId', isEqualTo: userId);
        break;
      case UserType.delivery:
        query = _firestore
            .collection('orders')
            .where('deliveryPersonId', isEqualTo: userId)
            .where('status', whereIn: [
          OrderStatus.accepted.index,
          OrderStatus.inProgress.index
        ]);
        break;
      case UserType.restaurant:
        query = _firestore
            .collection('orders')
            .where('restaurantId', isEqualTo: userId);
        break;
      case UserType.admin:
        query = _firestore
            .collection('orders')
            .orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: status.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toMap());

      await _notificationService.sendNotificationToRestaurant(
          order.restaurantId, 'Nouvelle commande!');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptOrderByRestaurant(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': OrderStatus.accepted.index,
      'acceptedAt': DateTime.now().toIso8601String(),
    });

    final order = await _firestore.collection('orders').doc(orderId).get();
    await _notificationService.sendNotificationToAvailableDelivery();
  }

  Future<void> acceptOrderByDelivery(
      String orderId, String deliveryPersonId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'deliveryPersonId': deliveryPersonId,
      'status': OrderStatus.inProgress.index,
    });

    final order = await _firestore.collection('orders').doc(orderId).get();
    final orderData = order.data() as Map<String, dynamic>;
    await _notificationService.sendNotificationToClient(
        orderData['clientId'], 'Votre commande est en cours de livraison!');
  }

  Future<void> completeOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': OrderStatus.delivered.index,
      'deliveredAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateDeliveryLocation(
      String orderId, Map<String, dynamic> location) async {
    await _firestore.collection('orders').doc(orderId).update({
      'currentDeliveryLocation': location,
    });
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': OrderStatus.cancelled.index,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancellationReason': reason,
    });
  }

  Future<String?> getLastOrderAddress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('clientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return data['deliveryAddress'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting last order address: $e');
      return null;
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }
}
