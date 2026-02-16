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

  RestaurantModel({
    required this.uid,
    required this.name,
    this.phoneNumber,
    this.location,
    this.approvedItemsCount = 0,
    this.totalItemsCount = 0,
  });
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
  Map<String, CartItem> _cart =
      {}; // Changed to store CartItem instead of MenuItem
  bool _isLoading = false;
  String? _error;

  List<RestaurantModel> get restaurants => _restaurants;
  List<MenuItem> get restaurantMenuItems => _restaurantMenuItems;
  Map<String, CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get cartItemCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      _cart.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Load restaurants
  Future<void> loadRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 [CLIENT_PROVIDER] Loading restaurants...');

      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: UserType.restaurant.index)
          .where('approvalStatus', isEqualTo: ApprovalStatus.approved.index)
          .get()
          .timeout(const Duration(seconds: 15));

      print(
          '🔵 [CLIENT_PROVIDER] Found ${snapshot.docs.length} approved restaurants');

      List<RestaurantModel> tempRestaurants = [];
      for (var doc in snapshot.docs) {
        final userData = doc.data();

        final menuSnapshot = await _firestore
            .collection('menuItems')
            .where('restaurantId', isEqualTo: doc.id)
            .where('status', isEqualTo: 'approved')
            .get()
            .timeout(const Duration(seconds: 10));

        tempRestaurants.add(RestaurantModel(
          uid: doc.id,
          name: userData['restaurantName'] ?? userData['name'] ?? 'Restaurant',
          phoneNumber: userData['phoneNumber'],
          location: userData['location'],
          approvedItemsCount: menuSnapshot.docs.length,
        ));
      }

      _restaurants = tempRestaurants;
      print('✅ [CLIENT_PROVIDER] Loaded ${_restaurants.length} restaurants');
    } on TimeoutException catch (e) {
      _error = 'Timeout: $e';
      print('❌ [CLIENT_PROVIDER] Timeout: $e');
      _restaurants = [];
    } catch (e) {
      _error = 'Erreur: $e';
      print('❌ [CLIENT_PROVIDER] Error: $e');
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
      print('❌ [CLIENT_PROVIDER] Error getting restaurant: $e');
    }
    return null;
  }
}
