// lib/providers/menu_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/menu_item_model.dart';

class MenuProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MenuItem> get approvedItems => _menuItems
      .where((item) => item.status == MenuItemStatus.approved)
      .toList();

  List<MenuItem> get pendingItems => _menuItems
      .where((item) => item.status == MenuItemStatus.pending)
      .toList();

  List<MenuItem> get rejectedItems => _menuItems
      .where((item) => item.status == MenuItemStatus.rejected)
      .toList();

  // Load menu items for a restaurant
  Future<void> loadMenuItems(String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('menuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .get();

      _menuItems =
          snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
    } catch (e) {
      _error = 'Erreur lors du chargement du menu: $e';
      print('Error loading menu items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new menu item (pending approval)
  Future<bool> addMenuItem({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    required String category,
    File? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${restaurantId}.jpg';
        final ref = _storage.ref().child('menu_items/$restaurantId/$fileName');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final menuItem = MenuItem(
        id: '',
        restaurantId: restaurantId,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
        isAvailable: true,
        status: MenuItemStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('menuItems').add(menuItem.toFirestore());
      await loadMenuItems(restaurantId);
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du plat: $e';
      print('Error adding menu item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update menu item
  Future<bool> updateMenuItem({
    required String itemId,
    required String restaurantId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    File? newImageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;

      // Upload new image if provided
      if (newImageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${restaurantId}.jpg';
        final ref = _storage.ref().child('menu_items/$restaurantId/$fileName');
        await ref.putFile(newImageFile);
        updateData['imageUrl'] = await ref.getDownloadURL();

        // If updating content, reset to pending status
        updateData['status'] =
            MenuItemStatus.pending.toString().split('.').last;
      }

      await _firestore.collection('menuItems').doc(itemId).update(updateData);
      await loadMenuItems(restaurantId);
      return true;
    } catch (e) {
      _error = 'Erreur lors de la modification: $e';
      print('Error updating menu item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete menu item
  Future<bool> deleteMenuItem(String itemId, String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('menuItems').doc(itemId).delete();
      await loadMenuItems(restaurantId);
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      print('Error deleting menu item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(
      String itemId, String restaurantId, bool currentStatus) async {
    try {
      await _firestore.collection('menuItems').doc(itemId).update({
        'isAvailable': !currentStatus,
      });
      await loadMenuItems(restaurantId);
    } catch (e) {
      _error = 'Erreur lors du changement de disponibilité: $e';
      notifyListeners();
    }
  }

  // Admin: Approve menu item
  Future<bool> approveMenuItem(String itemId) async {
    try {
      await _firestore.collection('menuItems').doc(itemId).update({
        'status': MenuItemStatus.approved.toString().split('.').last,
        'approvedAt': Timestamp.now(),
        'rejectionReason': null,
      });
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'approbation: $e';
      return false;
    }
  }

  // Admin: Reject menu item
  Future<bool> rejectMenuItem(String itemId, String reason) async {
    try {
      await _firestore.collection('menuItems').doc(itemId).update({
        'status': MenuItemStatus.rejected.toString().split('.').last,
        'rejectionReason': reason,
      });
      return true;
    } catch (e) {
      _error = 'Erreur lors du rejet: $e';
      return false;
    }
  }
}
