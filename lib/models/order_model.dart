// lib/models/order_model.dart (Updated)
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

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      clientId: map['clientId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      deliveryPersonId: map['deliveryPersonId'],
      status: OrderStatus.values[map['status'] ?? 0],
      items: (map['items'] as List).map((e) => OrderItem.fromMap(e)).toList(),
      deliveryLocation: map['deliveryLocation'] ?? {},
      restaurantLocation: map['restaurantLocation'] ?? {},
      currentDeliveryLocation: map['currentDeliveryLocation'],
      createdAt: DateTime.parse(map['createdAt']),
      acceptedAt:
          map['acceptedAt'] != null ? DateTime.parse(map['acceptedAt']) : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'])
          : null,
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
}
