// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, accepted, inProgress, delivered, cancelled }

enum PaymentMethod { cash, card }

enum PaymentStatus { pending, paid }

class OrderModel {
  final String orderId;
  final String clientId;
  final String restaurantId;
  final String? deliveryPersonId;
  final OrderStatus status;
  final List<OrderItem> items;
  final Map<String, dynamic> deliveryLocation;
  final Map<String, dynamic> restaurantLocation;
  final Map<String, dynamic>? currentDeliveryLocation;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? clientComment;
  final String? clientName;
  final String? clientPhone;
  final String? deliveryAddress;

  OrderModel({
    required this.orderId,
    required this.clientId,
    required this.restaurantId,
    this.deliveryPersonId,
    required this.status,
    required this.items,
    required this.deliveryLocation,
    required this.restaurantLocation,
    this.currentDeliveryLocation,
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    required this.subtotal,
    this.deliveryFee = 14.0,
    this.serviceFee = 2.0,
    required this.total,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.clientComment,
    this.clientName,
    this.clientPhone,
    this.deliveryAddress,
  });

  // ✅ Universal DateTime parser (same as MenuItem)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is Map) {
        final seconds = value['_seconds'] ?? value['seconds'];
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing DateTime in OrderModel: $e');
    }

    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    try {
      return OrderModel(
        orderId: map['orderId'] ?? '',
        clientId: map['clientId'] ?? '',
        restaurantId: map['restaurantId'] ?? '',
        deliveryPersonId: map['deliveryPersonId'],
        status: OrderStatus.values[map['status'] ?? 0],
        items: (map['items'] as List? ?? [])
            .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        deliveryLocation:
            map['deliveryLocation'] as Map<String, dynamic>? ?? {},
        restaurantLocation:
            map['restaurantLocation'] as Map<String, dynamic>? ?? {},
        currentDeliveryLocation:
            map['currentDeliveryLocation'] as Map<String, dynamic>?,
        createdAt: _parseDateTime(map['createdAt']),
        acceptedAt: _parseDateTimeNullable(map['acceptedAt']),
        deliveredAt: _parseDateTimeNullable(map['deliveredAt']),
        subtotal: (map['subtotal'] ?? 0).toDouble(),
        deliveryFee: (map['deliveryFee'] ?? 14.0).toDouble(),
        serviceFee: (map['serviceFee'] ?? 2.0).toDouble(),
        total: (map['total'] ?? 0).toDouble(),
        paymentMethod: PaymentMethod.values[map['paymentMethod'] ?? 0],
        paymentStatus: PaymentStatus.values[map['paymentStatus'] ?? 0],
        clientComment: map['clientComment'],
        clientName: map['clientName'],
        clientPhone: map['clientPhone'],
        deliveryAddress: map['deliveryAddress'],
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing OrderModel: $e');
      print('Stack trace: $stackTrace');
      print('Order data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'clientId': clientId,
      'restaurantId': restaurantId,
      'deliveryPersonId': deliveryPersonId,
      'status': status.index,
      'items': items.map((e) => e.toMap()).toList(),
      'deliveryLocation': deliveryLocation,
      'restaurantLocation': restaurantLocation,
      'currentDeliveryLocation': currentDeliveryLocation,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'total': total,
      'paymentMethod': paymentMethod.index,
      'paymentStatus': paymentStatus.index,
      'clientComment': clientComment,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'deliveryAddress': deliveryAddress,
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? clientId,
    String? restaurantId,
    String? deliveryPersonId,
    OrderStatus? status,
    List<OrderItem>? items,
    Map<String, dynamic>? deliveryLocation,
    Map<String, dynamic>? restaurantLocation,
    Map<String, dynamic>? currentDeliveryLocation,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? deliveredAt,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? total,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? clientComment,
    String? clientName,
    String? clientPhone,
    String? deliveryAddress,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      clientId: clientId ?? this.clientId,
      restaurantId: restaurantId ?? this.restaurantId,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      status: status ?? this.status,
      items: items ?? this.items,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      currentDeliveryLocation:
          currentDeliveryLocation ?? this.currentDeliveryLocation,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      clientComment: clientComment ?? this.clientComment,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  OrderItem copyWith({
    String? name,
    int? quantity,
    double? price,
  }) {
    return OrderItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
