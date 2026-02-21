// lib/providers/client_provider.dart
// UPDATED with quantity management

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/menu_item_model.dart';

class RestaurantModel {
  final String uid;
  final String name;
  final String? phoneNumber;
  final Map<String, dynamic>? location;
  final int approvedItemsCount;
  final int totalItemsCount;
  final String category;
  final String? coverImageUrl;
  final double averageRating;
  final int totalReviews;

  RestaurantModel({
    required this.uid,
    required this.name,
    this.phoneNumber,
    this.location,
    this.approvedItemsCount = 0,
    this.totalItemsCount = 0,
    this.category = '',
    this.coverImageUrl,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });
}

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final bool isDefault;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  factory SavedAddress.fromMap(String id, Map<String, dynamic> map) {
    return SavedAddress(
      id: id,
      label: map['label'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }
}

class PromoCode {
  final String id;
  final String code;
  final double? discountPercent;
  final double? discountAmount;
  final double minOrder;
  final DateTime expiresAt;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.code,
    this.discountPercent,
    this.discountAmount,
    this.minOrder = 0,
    required this.expiresAt,
    this.isActive = true,
  });

  factory PromoCode.fromMap(String id, Map<String, dynamic> map) {
    return PromoCode(
      id: id,
      code: map['code'] ?? '',
      discountPercent: (map['discountPercent'] as num?)?.toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      minOrder: (map['minOrder'] ?? 0).toDouble(),
      expiresAt: map['expiresAt'] is Timestamp
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;
}

class ClientProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RestaurantModel> _restaurants = [];
  List<MenuItem> _restaurantMenuItems = [];
  Map<String, CartItem> _cart = {};
  bool _isLoading = false;
  String? _error;

  // Favorites
  Set<String> _favoriteRestaurantIds = {};

  // Saved addresses
  List<SavedAddress> _savedAddresses = [];

  // Promo code
  PromoCode? _appliedPromo;
  double _promoDiscount = 0.0;

  List<RestaurantModel> get restaurants => _restaurants;
  List<MenuItem> get restaurantMenuItems => _restaurantMenuItems;
  Map<String, CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get favoriteRestaurantIds => _favoriteRestaurantIds;
  List<SavedAddress> get savedAddresses => _savedAddresses;
  PromoCode? get appliedPromo => _appliedPromo;
  double get promoDiscount => _promoDiscount;

  int get cartItemCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      _cart.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Load restaurants - optimized: single query for menu counts
  Future<void> loadRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: UserType.restaurant.index)
          .where('approvalStatus', isEqualTo: ApprovalStatus.approved.index)
          .get()
          .timeout(const Duration(seconds: 15));

      // Fetch all approved menu items in a single query
      final menuSnapshot = await _firestore
          .collection('menuItems')
          .where('status', isEqualTo: 'approved')
          .get()
          .timeout(const Duration(seconds: 15));

      // Group menu item counts by restaurantId
      final Map<String, int> menuCounts = {};
      for (var doc in menuSnapshot.docs) {
        final rid = doc.data()['restaurantId'] as String?;
        if (rid != null) {
          menuCounts[rid] = (menuCounts[rid] ?? 0) + 1;
        }
      }

      // Also fetch reviews to compute average ratings
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .get()
          .timeout(const Duration(seconds: 15));

      final Map<String, List<double>> ratingsMap = {};
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final rid = data['restaurantId'] as String?;
        final rating = (data['rating'] ?? 0).toDouble();
        if (rid != null && rating > 0) {
          ratingsMap.putIfAbsent(rid, () => []).add(rating);
        }
      }

      List<RestaurantModel> tempRestaurants = [];
      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final ratings = ratingsMap[doc.id] ?? [];
        final avgRating = ratings.isEmpty
            ? 0.0
            : ratings.reduce((a, b) => a + b) / ratings.length;

        tempRestaurants.add(RestaurantModel(
          uid: doc.id,
          name: userData['restaurantName'] ?? userData['name'] ?? 'Restaurant',
          phoneNumber: userData['phoneNumber'],
          location: userData['location'],
          approvedItemsCount: menuCounts[doc.id] ?? 0,
          category: userData['restaurantCategory'] ?? '',
          coverImageUrl: userData['profileImageUrl'],
          averageRating: avgRating,
          totalReviews: ratings.length,
        ));
      }

      _restaurants = tempRestaurants;
    } on TimeoutException catch (e) {
      _error = 'Timeout: $e';
      _restaurants = [];
    } catch (e) {
      _error = 'Erreur: $e';
      _restaurants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load menu items
  Future<void> loadRestaurantMenu(String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 [CLIENT_PROVIDER] Loading menu for restaurant: $restaurantId');

      final snapshot = await _firestore
          .collection('menuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'approved')
          .where('isAvailable', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 15));

      print('🔵 [CLIENT_PROVIDER] Found ${snapshot.docs.length} menu items');

      _restaurantMenuItems =
          snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();

      _restaurantMenuItems.sort((a, b) => a.category.compareTo(b.category));

      print(
          '✅ [CLIENT_PROVIDER] Loaded ${_restaurantMenuItems.length} menu items');
    } on TimeoutException catch (e) {
      _error = 'Timeout: $e';
      print('❌ [CLIENT_PROVIDER] Timeout: $e');
      _restaurantMenuItems = [];
    } catch (e) {
      _error = 'Erreur: $e';
      print('❌ [CLIENT_PROVIDER] Error: $e');
      _restaurantMenuItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cart management with quantity
  void addToCart(MenuItem item, {int quantity = 1}) {
    if (_cart.containsKey(item.id)) {
      _cart[item.id]!.quantity += quantity;
    } else {
      _cart[item.id] = CartItem(menuItem: item, quantity: quantity);
    }
    print('🛒 [CLIENT_PROVIDER] Added ${item.name} (qty: $quantity)');
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cart.remove(itemId);
    print('🛒 [CLIENT_PROVIDER] Removed from cart');
    notifyListeners();
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(itemId);
    } else if (_cart.containsKey(itemId)) {
      _cart[itemId]!.quantity = newQuantity;
      print('🛒 [CLIENT_PROVIDER] Updated quantity: $newQuantity');
      notifyListeners();
    }
  }

  void incrementQuantity(String itemId) {
    if (_cart.containsKey(itemId)) {
      _cart[itemId]!.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String itemId) {
    if (_cart.containsKey(itemId)) {
      if (_cart[itemId]!.quantity > 1) {
        _cart[itemId]!.quantity--;
      } else {
        removeFromCart(itemId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    print('🛒 [CLIENT_PROVIDER] Cart cleared');
    notifyListeners();
  }

  bool isInCart(String itemId) {
    return _cart.containsKey(itemId);
  }

  int getQuantity(String itemId) {
    return _cart[itemId]?.quantity ?? 0;
  }

  // Get restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    try {
      final doc = await _firestore.collection('users').doc(restaurantId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return RestaurantModel(
          uid: doc.id,
          name: data['restaurantName'] ?? data['name'] ?? 'Restaurant',
          phoneNumber: data['phoneNumber'],
          location: data['location'],
        );
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // ==================== FAVORITES ====================

  Future<void> loadFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      _favoriteRestaurantIds = snapshot.docs
          .map((doc) => doc.data()['restaurantId'] as String)
          .toSet();
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  bool isFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }

  Future<void> toggleFavorite(String userId, String restaurantId) async {
    try {
      if (_favoriteRestaurantIds.contains(restaurantId)) {
        // Remove favorite
        final snapshot = await _firestore
            .collection('favorites')
            .where('userId', isEqualTo: userId)
            .where('restaurantId', isEqualTo: restaurantId)
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        _favoriteRestaurantIds.remove(restaurantId);
      } else {
        // Add favorite
        await _firestore.collection('favorites').add({
          'userId': userId,
          'restaurantId': restaurantId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _favoriteRestaurantIds.add(restaurantId);
      }
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  // ==================== RATINGS & REVIEWS ====================

  Future<void> submitReview({
    required String userId,
    required String restaurantId,
    required String orderId,
    required double rating,
    String? comment,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'userId': userId,
        'restaurantId': restaurantId,
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadRestaurantReviews(
      String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== SAVED ADDRESSES ====================

  Future<void> loadAddresses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();
      _savedAddresses = snapshot.docs
          .map((doc) => SavedAddress.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> addAddress(String userId, SavedAddress address) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .add(address.toMap());
      _savedAddresses.add(SavedAddress(
        id: docRef.id,
        label: address.label,
        address: address.address,
        latitude: address.latitude,
        longitude: address.longitude,
        isDefault: address.isDefault,
      ));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      _savedAddresses.removeWhere((a) => a.id == addressId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== PROMOTIONS & COUPONS ====================

  Future<String?> validatePromoCode(String code, double orderTotal) async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'Code promo invalide';
      }

      final promo =
          PromoCode.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());

      if (promo.expiresAt.isBefore(DateTime.now())) {
        return 'Code promo expiré';
      }

      if (orderTotal < promo.minOrder) {
        return 'Commande minimum: ${promo.minOrder.toStringAsFixed(2)} DHs';
      }

      _appliedPromo = promo;
      if (promo.discountPercent != null) {
        _promoDiscount = orderTotal * promo.discountPercent! / 100;
      } else if (promo.discountAmount != null) {
        _promoDiscount = promo.discountAmount!;
      }
      notifyListeners();
      return null; // null means success
    } catch (e) {
      return 'Erreur de validation';
    }
  }

  void clearPromo() {
    _appliedPromo = null;
    _promoDiscount = 0.0;
    notifyListeners();
  }

  // ==================== SEARCH ====================

  Future<List<MenuItem>> searchMenuItems(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('menuItems')
          .where('status', isEqualTo: 'approved')
          .where('isAvailable', isEqualTo: true)
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc))
          .where((item) =>
              item.name.toLowerCase().contains(lowerQuery) ||
              item.description.toLowerCase().contains(lowerQuery) ||
              item.category.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
