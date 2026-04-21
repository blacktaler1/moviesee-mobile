import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'app.dart';
import 'core/logger/app_logger.dart';
import 'data/services/notification_service.dart';

void main() {
  // runTalkerZonedGuarded ichida WidgetsFlutterBinding.ensureInitialized() chaqirish kerak
  // Aks holda "Zone mismatch" xatosi chiqadi
  runTalkerZonedGuarded(
    appLogger,
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      MediaKit.ensureInitialized();
      await Firebase.initializeApp();
      await NotificationService.initialize();

      appLogger.info('=== MovieSee ishga tushmoqda ===');

      runApp(
        ProviderScope(
          observers: [
            TalkerRiverpodObserver(
              talker: appLogger,
              settings: const TalkerRiverpodLoggerSettings(
                printStateFullData: false,
              ),
            ),
          ],
          child: const MovieSeeApp(),
        ),
      );
    },
    (error, stack) => appLogger.error('Unhandled error', error, stack),
  );
}
