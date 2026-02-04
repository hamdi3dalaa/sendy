// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.messageId}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sendy_channel',
      'Sendy Notifications',
      channelDescription: 'Notifications for Sendy delivery app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Sendy',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  Future<void> sendNotificationToRestaurant(
      String restaurantId, String message) async {
    final doc = await _firestore.collection('users').doc(restaurantId).get();
    final data = doc.data();
    if (data != null && data['fcmToken'] != null) {
      // You'll need to implement Cloud Functions for sending FCM
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
