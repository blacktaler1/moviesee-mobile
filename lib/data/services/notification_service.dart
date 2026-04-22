import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'storage_service.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'moviesee_invites',
    'Xona Takliflari',
    description: 'Do\'stingiz sizni xonaga taklif qilganda bildirishnoma',
    importance: Importance.high,
    playSound: true,
  );

  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotif.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    final token = await _messaging.getToken();
    if (token != null) await _saveFcmToken(token);
    _messaging.onTokenRefresh.listen(_saveFcmToken);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessage(initial);
  }

  static Future<void> _saveFcmToken(String token) async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken != null) await ApiService.saveFcmToken(token);
    } catch (_) {}
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotif.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['room_code'],
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final roomCode = response.payload;
    if (roomCode != null && roomCode.isNotEmpty) {
      navigatorKey.currentContext?.go('/room/$roomCode');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    final roomCode = message.data['room_code'];
    if (roomCode != null) {
      navigatorKey.currentContext?.go('/room/$roomCode');
    }
  }
}
