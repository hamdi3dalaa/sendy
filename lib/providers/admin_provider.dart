// lib/providers/admin_provider.dart
// Fixed version - no orderBy to avoid index requirements

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/menu_item_model.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _pendingUsers = [];
  List<MenuItem> _pendingMenuItems = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get pendingUsers => _pendingUsers;
  List<MenuItem> get pendingMenuItems => _pendingMenuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<UserModel> get pendingDelivery => _pendingUsers
      .where((u) => u.userType == UserType.delivery && u.isPending)
      .toList();

  List<UserModel> get pendingRestaurants => _pendingUsers
      .where((u) => u.userType == UserType.restaurant && u.isPending)
      .toList();

  // Load all pending users - FIXED: removed orderBy
  Future<void> loadPendingUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 [ADMIN_PROVIDER] Loading pending users...');

      final snapshot = await _firestore
          .collection('users')
          .where('approvalStatus', isEqualTo: ApprovalStatus.pending.index)
          .get();

      print('🔵 [ADMIN_PROVIDER] Found ${snapshot.docs.length} pending users');

      _pendingUsers =
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

      // Sort in memory instead of using orderBy
      _pendingUsers.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      print('✅ [ADMIN_PROVIDER] Loaded ${_pendingUsers.length} pending users');
    } catch (e) {
      _error = 'Erreur lors du chargement des utilisateurs: $e';
      print('❌ [ADMIN_PROVIDER] Error loading pending users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all pending menu items - FIXED: removed orderBy
  Future<void> loadPendingMenuItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 [ADMIN_PROVIDER] Loading pending menu items...');

      final snapshot = await _firestore
          .collection('menuItems')
          .where('status', isEqualTo: 'pending')
          .get();

      print(
        '🔵 [ADMIN_PROVIDER] Found ${snapshot.docs.length} pending menu items',
      );

      _pendingMenuItems = snapshot.docs.map((doc) {
        print('🔵 [ADMIN_PROVIDER] Processing menu item: ${doc.id}');
        return MenuItem.fromFirestore(doc);
      }).toList();

      // Sort in memory instead of using orderBy
      _pendingMenuItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
        '✅ [ADMIN_PROVIDER] Loaded ${_pendingMenuItems.length} pending menu items',
      );
    } catch (e) {
      _error = 'Erreur lors du chargement des plats: $e';
      print('❌ [ADMIN_PROVIDER] Error loading pending menu items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Approve user
  Future<bool> approveUser(String uid, String adminUid) async {
    try {
      print('🔵 [ADMIN_PROVIDER] Approving user: $uid');

      await _firestore.collection('users').doc(uid).update({
        'approvalStatus': ApprovalStatus.approved.index,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminUid,
      });

      // Log the approval
      await _firestore.collection('approval_logs').add({
        'type': 'user',
        'targetId': uid,
        'action': 'approved',
        'adminUid': adminUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reload pending users
      await loadPendingUsers();

      print('✅ [ADMIN_PROVIDER] User approved successfully');
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'approbation: $e';
      print('❌ [ADMIN_PROVIDER] Error approving user: $e');
      notifyListeners();
      return false;
    }
  }

  // Reject user
  Future<bool> rejectUser(String uid, String reason, String adminUid) async {
    try {
      print('🔵 [ADMIN_PROVIDER] Rejecting user: $uid');

      await _firestore.collection('users').doc(uid).update({
        'approvalStatus': ApprovalStatus.rejected.index,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminUid,
      });

      // Log the rejection
      await _firestore.collection('approval_logs').add({
        'type': 'user',
        'targetId': uid,
        'action': 'rejected',
        'reason': reason,
        'adminUid': adminUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reload pending users
      await loadPendingUsers();

      print('✅ [ADMIN_PROVIDER] User rejected successfully');
      return true;
    } catch (e) {
      _error = 'Erreur lors du rejet: $e';
      print('❌ [ADMIN_PROVIDER] Error rejecting user: $e');
      notifyListeners();
      return false;
    }
  }

  // Approve menu item
  Future<bool> approveMenuItem(String itemId, String adminUid) async {
    try {
      print('🔵 [ADMIN_PROVIDER] Approving menu item: $itemId');

      await _firestore.collection('menuItems').doc(itemId).update({
        'status': MenuItemStatus.approved.toString().split('.').last,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminUid,
        'rejectionReason': null,
      });

      // Log the approval
      await _firestore.collection('approval_logs').add({
        'type': 'menu_item',
        'targetId': itemId,
        'action': 'approved',
        'adminUid': adminUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reload pending items
      await loadPendingMenuItems();

      print('✅ [ADMIN_PROVIDER] Menu item approved successfully');
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'approbation: $e';
      print('❌ [ADMIN_PROVIDER] Error approving menu item: $e');
      notifyListeners();
      return false;
    }
  }

  // Reject menu item
  Future<bool> rejectMenuItem(
    String itemId,
    String reason,
    String adminUid,
  ) async {
    try {
      print('🔵 [ADMIN_PROVIDER] Rejecting menu item: $itemId');

      await _firestore.collection('menuItems').doc(itemId).update({
        'status': MenuItemStatus.rejected.toString().split('.').last,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminUid,
      });

      // Log the rejection
      await _firestore.collection('approval_logs').add({
        'type': 'menu_item',
        'targetId': itemId,
        'action': 'rejected',
        'reason': reason,
        'adminUid': adminUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reload pending items
      await loadPendingMenuItems();

      print('✅ [ADMIN_PROVIDER] Menu item rejected successfully');
      return true;
    } catch (e) {
      _error = 'Erreur lors du rejet: $e';
      print('❌ [ADMIN_PROVIDER] Error rejecting menu item: $e');
      notifyListeners();
      return false;
    }
  }

  // Get restaurant name by ID
  Future<String> getRestaurantName(String restaurantId) async {
    try {
      print('🔵 [ADMIN_PROVIDER] Getting restaurant name for: $restaurantId');

      final doc = await _firestore.collection('users').doc(restaurantId).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        final name = user.restaurantName ?? user.displayName;
        print('✅ [ADMIN_PROVIDER] Restaurant name: $name');
        return name;
      }

      print('⚠️ [ADMIN_PROVIDER] Restaurant not found');
      return 'Restaurant inconnu';
    } catch (e) {
      print('❌ [ADMIN_PROVIDER] Error getting restaurant name: $e');
      return 'Erreur';
    }
  }
}
