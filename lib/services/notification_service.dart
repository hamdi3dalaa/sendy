// lib/services/notification_service.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Global navigator key for handling notification taps from background/killed state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification channel for order alerts (high priority with sound)
  static const String _orderChannelId = 'sendy_orders';
  static const String _orderChannelName = 'Commandes';
  static const String _orderChannelDesc = 'Notifications de nouvelles commandes';

  // Default notification channel
  static const String _defaultChannelId = 'sendy_channel';
  static const String _defaultChannelName = 'Sendy Notifications';
  static const String _defaultChannelDesc = 'Notifications for Sendy delivery app';

  // Action IDs for notification buttons
  static const String actionAcceptOrder = 'ACCEPT_ORDER';
  static const String actionRejectOrder = 'REJECT_ORDER';

  // Pending notification data (for when user taps notification)
  static Map<String, dynamic>? pendingNotificationData;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings permissionSettings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permissionSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Define notification action buttons for order notifications
    const acceptAction = AndroidNotificationAction(
      actionAcceptOrder,
      'Accepter',
      icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      showsUserInterface: true,
    );
    const rejectAction = AndroidNotificationAction(
      actionRejectOrder,
      'Rejeter',
      icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      showsUserInterface: true,
    );

    // Android notification channels
    const orderChannel = AndroidNotificationChannel(
      _orderChannelId,
      _orderChannelName,
      description: _orderChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF5722),
    );

    const defaultChannel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: _defaultChannelDesc,
      importance: Importance.high,
      playSound: true,
    );

    // Create channels
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(orderChannel);
      await androidPlugin.createNotificationChannel(defaultChannel);
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      pendingNotificationData = initialMessage.data;
    }
  }

  /// Called when user interacts with a notification (tap or action button)
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;

      // Handle action button press
      if (response.actionId == actionAcceptOrder) {
        _handleAcceptFromNotification(data);
        return;
      }
      if (response.actionId == actionRejectOrder) {
        _handleRejectFromNotification(data);
        return;
      }

      // Handle regular tap - navigate to orders
      _handleNotificationTap(data);
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }

  /// Accept order directly from notification action
  Future<void> _handleAcceptFromNotification(Map<String, dynamic> data) async {
    final orderId = data['orderId'];
    if (orderId == null) return;

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 1, // OrderStatus.accepted
        'acceptedAt': DateTime.now().toIso8601String(),
      });
      print('Order $orderId accepted from notification');
    } catch (e) {
      print('Error accepting order from notification: $e');
    }
  }

  /// Reject order directly from notification action
  Future<void> _handleRejectFromNotification(Map<String, dynamic> data) async {
    final orderId = data['orderId'];
    if (orderId == null) return;

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 4, // OrderStatus.cancelled
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': 'Rejeté depuis la notification',
      });
      print('Order $orderId rejected from notification');
    } catch (e) {
      print('Error rejecting order from notification: $e');
    }
  }

  /// Handle notification tap - store data for navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    pendingNotificationData = data;
    // Try to navigate if navigator is available
    _navigateFromNotification(data);
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      // Navigator not ready, data stored in pendingNotificationData
      return;
    }

    switch (type) {
      case 'new_order':
        navigator.pushNamed('/incoming-orders');
        pendingNotificationData = null;
        break;
      case 'delivery_available':
        navigator.pushNamed('/available-orders');
        pendingNotificationData = null;
        break;
    }
  }

  /// Check and handle any pending notification navigation
  void checkPendingNotification() {
    if (pendingNotificationData != null) {
      _navigateFromNotification(pendingNotificationData!);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    final isOrderNotification = type == 'new_order';
    final payloadJson = json.encode(data);

    if (isOrderNotification) {
      // High-priority order notification with accept/reject actions
      final androidDetails = AndroidNotificationDetails(
        _orderChannelId,
        _orderChannelName,
        channelDescription: _orderChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFFF5722),
        ledOnMs: 500,
        ledOffMs: 500,
        fullScreenIntent: true, // Shows heads-up even when app killed
        category: AndroidNotificationCategory.call, // High priority category
        visibility: NotificationVisibility.public,
        actions: const [
          AndroidNotificationAction(
            actionAcceptOrder,
            'Accepter ✓',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionRejectOrder,
            'Rejeter ✗',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Nouvelle commande!',
        message.notification?.body ?? '',
        details,
        payload: payloadJson,
      );
    } else {
      // Default notification
      const androidDetails = AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: _defaultChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Sendy',
        message.notification?.body ?? '',
        details,
        payload: payloadJson,
      );
    }
  }

  Future<void> sendNotificationToRestaurant(
      String restaurantId, String message) async {
    final doc = await _firestore.collection('users').doc(restaurantId).get();
    final data = doc.data();
    if (data != null && data['fcmToken'] != null) {
      print('Send notification to restaurant: $message');
    }
  }

  Future<void> sendNotificationToClient(String clientId, String message) async {
    final doc = await _firestore.collection('users').doc(clientId).get();
    final data = doc.data();
    if (data != null && data['fcmToken'] != null) {
      print('Send notification to client: $message');
    }
  }

  Future<void> sendNotificationToAvailableDelivery() async {
    print('Send notification to available delivery persons');
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
