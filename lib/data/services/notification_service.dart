import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/logger/app_logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  appLogger.info('[FCM] Background: ${message.messageId}');
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _fcm.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen(_onForeground);
    appLogger.info('[FCM] NotificationService initialized');
  }

  static Future<String?> getToken() => _fcm.getToken();

  static void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    appLogger.info('[FCM] Foreground: ${n.title}');
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'moviesee_channel',
          'MovieSee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
