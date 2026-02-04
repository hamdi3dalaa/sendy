// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

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
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> createOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.orderId).set(order.toMap());
    await _notificationService.sendNotificationToRestaurant(
        order.restaurantId, 'Nouvelle commande!');
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
}
