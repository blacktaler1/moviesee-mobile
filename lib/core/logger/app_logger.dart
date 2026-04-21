import 'package:talker_flutter/talker_flutter.dart';

/// Ilovaning markazlashtirilgan logger singleton'i.
/// Siz ishlatayotgan loyihalardagi (dewibe_erp, rentifyapp) pattern bilan bir xil.
///
/// Ishlatish:
///   AppLogger.talker.info('[API] So'rov yuborildi');
///   AppLogger.talker.warning('[WS] Ulanish uzildi');
///   AppLogger.talker.error('[PLAYER] Video yuklanmadi', exception, stackTrace);
final appLogger = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: true,
    useConsoleLogs: true,
  ),
);
