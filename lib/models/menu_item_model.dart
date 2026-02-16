// lib/models/menu_item_model.dart
// COMPLETE VERSION with toFirestore() method

import 'package:cloud_firestore/cloud_firestore.dart';

enum MenuItemStatus { pending, approved, rejected }

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isAvailable;
  final MenuItemStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.status = MenuItemStatus.pending,
    required this.createdAt,
    this.approvedAt,
    this.rejectionReason,
  });

  // ✅ Universal DateTime parser
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
      print('⚠️ Error parsing DateTime: $e');
    }

    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return MenuItem(
        id: doc.id,
        restaurantId: data['restaurantId'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] is int)
            ? (data['price'] as int).toDouble()
            : (data['price'] ?? 0.0).toDouble(),
        imageUrl: data['imageUrl'],
        category: data['category'] ?? 'Autre',
        isAvailable: data['isAvailable'] ?? true,
        status: _parseStatus(data['status']),
        createdAt: _parseDateTime(data['createdAt']),
        approvedAt: _parseDateTimeNullable(data['approvedAt']),
        rejectionReason: data['rejectionReason'],
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing menu item ${doc.id}: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static MenuItemStatus _parseStatus(dynamic status) {
    if (status == null) return MenuItemStatus.pending;

    if (status is String) {
      switch (status.toLowerCase()) {
        case 'approved':
          return MenuItemStatus.approved;
        case 'rejected':
          return MenuItemStatus.rejected;
        case 'pending':
        default:
          return MenuItemStatus.pending;
      }
    }

    if (status is int) {
      if (status >= 0 && status < MenuItemStatus.values.length) {
        return MenuItemStatus.values[status];
      }
    }

    return MenuItemStatus.pending;
  }

  // ✅ Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  // ✅ NEW: Convert to Firestore format (same as toMap)
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  MenuItem copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    MenuItemStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return MenuItem(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
