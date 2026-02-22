// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../models/settlement_model.dart';
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

    // Increment delivery person's owedAmount by the service fee
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data()!;
      final deliveryPersonId = orderData['deliveryPersonId'] as String?;
      final serviceFee = (orderData['serviceFee'] as num?)?.toDouble() ?? 2.0;

      if (deliveryPersonId != null) {
        await _firestore.collection('users').doc(deliveryPersonId).update({
          'owedAmount': FieldValue.increment(serviceFee),
        });

        // Check if threshold reached (100 DHs)
        final userDoc =
            await _firestore.collection('users').doc(deliveryPersonId).get();
        if (userDoc.exists) {
          final owedAmount =
              (userDoc.data()!['owedAmount'] as num?)?.toDouble() ?? 0.0;
          if (owedAmount >= 100.0) {
            // Notify delivery person
            await _notificationService.sendNotificationToClient(
                deliveryPersonId,
                'Votre solde Sendy a atteint ${owedAmount.toStringAsFixed(0)} DH. Veuillez effectuer le reglement.');
            // Notify all admins
            await _notifyAdmins(
                'Le livreur doit ${owedAmount.toStringAsFixed(0)} DH de frais de service.');
          }
        }
      }
    }
  }

  Future<void> _notifyAdmins(String message) async {
    try {
      final admins = await _firestore
          .collection('users')
          .where('userType', isEqualTo: UserType.admin.index)
          .get();
      for (final admin in admins.docs) {
        final adminId = admin.data()['uid'] as String?;
        if (adminId != null) {
          await _notificationService.sendNotificationToClient(
              adminId, message);
        }
      }
    } catch (e) {
      print('Error notifying admins: $e');
    }
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

  // ── Settlement Methods ──

  /// Stream all approved delivery persons with their owedAmount
  Stream<List<Map<String, dynamic>>> getAllDeliveryPersonsWithFees() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: UserType.delivery.index)
        .where('approvalStatus', isEqualTo: 1) // approved
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'uid': data['uid'] ?? doc.id,
                'name': data['name'] ?? '',
                'phoneNumber': data['phoneNumber'] ?? '',
                'owedAmount':
                    (data['owedAmount'] as num?)?.toDouble() ?? 0.0,
                'profileImageUrl': data['profileImageUrl'],
              };
            }).toList());
  }

  /// Get the current owed amount for a delivery person
  Stream<double> getOwedAmount(String deliveryPersonId) {
    return _firestore
        .collection('users')
        .doc(deliveryPersonId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return (doc.data()!['owedAmount'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  /// Create a settlement request with proof image
  Future<void> createSettlement(SettlementModel settlement) async {
    await _firestore
        .collection('settlements')
        .doc(settlement.settlementId)
        .set(settlement.toMap());

    // Notify admins
    await _notifyAdmins(
        'Nouveau reglement de ${settlement.amount.toStringAsFixed(0)} DH envoye par ${settlement.deliveryPersonName}.');
  }

  /// Stream of pending settlements (for admin)
  Stream<List<SettlementModel>> getPendingSettlements() {
    return _firestore
        .collection('settlements')
        .where('status', isEqualTo: SettlementStatus.pending.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SettlementModel.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Stream of settlements for a specific delivery person
  Stream<List<SettlementModel>> getSettlementsForDelivery(
      String deliveryPersonId) {
    return _firestore
        .collection('settlements')
        .where('deliveryPersonId', isEqualTo: deliveryPersonId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SettlementModel.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Approve a settlement (admin)
  Future<void> approveSettlement(
      String settlementId, String adminUid) async {
    final doc = await _firestore
        .collection('settlements')
        .doc(settlementId)
        .get();
    if (!doc.exists) return;

    final settlement = SettlementModel.fromMap(doc.data()!);

    await _firestore.collection('settlements').doc(settlementId).update({
      'status': SettlementStatus.approved.index,
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': adminUid,
    });

    // Reset the delivery person's owedAmount
    await _firestore
        .collection('users')
        .doc(settlement.deliveryPersonId)
        .update({
      'owedAmount': FieldValue.increment(-settlement.amount),
    });

    // Notify delivery person
    await _notificationService.sendNotificationToClient(
        settlement.deliveryPersonId,
        'Votre reglement de ${settlement.amount.toStringAsFixed(0)} DH a ete approuve.');
  }

  /// Reject a settlement (admin)
  Future<void> rejectSettlement(
      String settlementId, String adminUid, String reason) async {
    final doc = await _firestore
        .collection('settlements')
        .doc(settlementId)
        .get();
    if (!doc.exists) return;

    final settlement = SettlementModel.fromMap(doc.data()!);

    await _firestore.collection('settlements').doc(settlementId).update({
      'status': SettlementStatus.rejected.index,
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': adminUid,
      'adminNote': reason,
    });

    // Notify delivery person
    await _notificationService.sendNotificationToClient(
        settlement.deliveryPersonId,
        'Votre reglement a ete refuse. Raison: $reason');
  }
}
