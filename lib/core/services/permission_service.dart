import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Mikrofon ruxsatini so'rash — WebRTC ovozli aloqa uchun.
  /// Play Market talabi: foydalanuvchiga nima uchun kerakligini tushuntirish shart.
  static Future<bool> requestMicrophone(BuildContext context) async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) await _showSettingsDialog(context, _micRationale);
      return false;
    }

    if (status.isDenied) {
      if (context.mounted) {
        final confirmed = await _showRationaleDialog(context, _micRationale);
        if (!confirmed) return false;
      }
    }

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Kamera ruxsatini so'rash — WebRTC video uchun.
  static Future<bool> requestCamera(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) await _showSettingsDialog(context, _camRationale);
      return false;
    }

    if (status.isDenied) {
      if (context.mounted) {
        final confirmed = await _showRationaleDialog(context, _camRationale);
        if (!confirmed) return false;
      }
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Bildirishnoma ruxsatini so'rash (Android 13+).
  static Future<bool> requestNotifications() async {
    if (await Permission.notification.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  // ── Rationale matnlari ──────────────────────────────────────

  static const _micRationale = _RationaleInfo(
    icon: Icons.mic_rounded,
    title: 'Mikrofon ruxsati',
    body: 'MovieSee xonada boshqa foydalanuvchilar bilan ovozli gaplashish '
        'uchun mikrofondan foydalanadi.\n\n'
        'Ovozli aloqa yozib olinmaydi va serverda saqlanmaydi.',
  );

  static const _camRationale = _RationaleInfo(
    icon: Icons.videocam_rounded,
    title: 'Kamera ruxsati',
    body: 'MovieSee video muloqot funksiyasi uchun kameradan foydalanadi.\n\n'
        'Video oqimi yozib olinmaydi.',
  );

  // ── Dialog'lar ──────────────────────────────────────────────

  static Future<bool> _showRationaleDialog(
      BuildContext context, _RationaleInfo info) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(info.icon, color: const Color(0xFFE50914), size: 22),
                const SizedBox(width: 10),
                Text(info.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            content: Text(info.body,
                style:
                    const TextStyle(color: Colors.white70, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Bekor qilish',
                    style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914)),
                child: const Text('Ruxsat berish'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _showSettingsDialog(
      BuildContext context, _RationaleInfo info) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(info.icon, color: Colors.orange, size: 22),
            const SizedBox(width: 10),
            Text(info.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '${info.body}\n\nRuxsat sozlamalardan qo\'lda yoqilishi kerak.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yopish',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914)),
            child: const Text('Sozlamalarga o\'tish'),
          ),
        ],
      ),
    );
  }
}

class _RationaleInfo {
  final IconData icon;
  final String title;
  final String body;
  const _RationaleInfo(
      {required this.icon, required this.title, required this.body});
}
