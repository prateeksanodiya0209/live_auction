import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Handling background message: ${message.messageId}');
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    try {
      // 1. Request FCM Permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('User granted notification permission');
      }

      // 2. Initialize Local Notifications for Heads-Up Banners
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          developer.log('Local notification tapped: ${response.payload}');
        },
      );

      // Create high-importance notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'auction_channel',
        'Auction Alerts',
        description: 'Notifications for outbid, victory, and start events',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Set FCM Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Handle Foreground FCM messages and display them as system notification banners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Got a message in foreground: ${message.messageId}');
        if (message.notification != null && context.mounted) {
          showLocalNotification(
            title: message.notification!.title ?? 'Live Auction Alert',
            body: message.notification!.body ?? '',
          );
        }
      });

      // 5. Handle notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('App opened from notification: ${message.messageId}');
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        developer.log('App launched from terminated state via notification: ${initialMessage.messageId}');
      }
    } catch (e) {
      developer.log('Error initializing FCM: $e');
    }
  }

  // Display a local system push notification banner
  Future<void> showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'auction_channel',
      'Auction Alerts',
      channelDescription: 'Notifications for outbid and winning events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: DateTime.now().microsecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  // Update FCM device token in Firestore
  Future<void> updateDeviceToken(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'deviceToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        developer.log('FCM Token updated successfully in Firestore: $token');
      }
    } catch (e) {
      developer.log('Error getting or updating FCM token: $e');
    }
  }

  // Helper method to setup real-time stream listener for new database notifications
  void listenToRealTimeNotifications(String userId) {
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final title = data['title'] as String? ?? 'Auction Update';
            final message = data['message'] as String? ?? '';
            // Display native push banner
            showLocalNotification(title: title, body: message);
          }
        }
      }
    });
  }
}
