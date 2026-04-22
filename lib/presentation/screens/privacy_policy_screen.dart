import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maxfiylik siyosati')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: Colors.white70, height: 1.6);
    final heading = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MovieSee — Maxfiylik Siyosati', style: heading),
        const SizedBox(height: 4),
        Text('Oxirgi yangilanish: 2025-yil', style: style?.copyWith(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 20),

        Text(
          'MovieSee ilovasidan foydalanishingiz ushbu maxfiylik siyosatini qabul qilganligingizni bildiradi.',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('1. Yig\'inadigan ma\'lumotlar', style: heading),
        const SizedBox(height: 8),
        Text(
          'Biz quyidagi ma\'lumotlarni yig\'amiz:\n'
          '• Foydalanuvchi nomi va elektron pochta manzili (ro\'yxatdan o\'tishda)\n'
          '• Parol (shifrlangan holda saqlanadi, hech qachon ochiq saqlanmaydi)\n'
          '• Firebase Cloud Messaging tokeni (push bildirishnomalar uchun)\n'
          '• Xona kodi va tomosha tarixi (sessiya davomida)',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('2. Mikrofon va kameradan foydalanish', style: heading),
        const SizedBox(height: 8),
        Text(
          'MovieSee ovozli aloqa (WebRTC) xizmati uchun mikrofondan foydalanadi. '
          'Kamera faqat video chat funksiyasi uchun so\'raladi.\n\n'
          'Ovozli aloqa ma\'lumotlari yozib olinmaydi va serverda saqlanmaydi — '
          'faqat real vaqtda foydalanuvchilar o\'rtasida uzatiladi.',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('3. Ma\'lumotlardan foydalanish', style: heading),
        const SizedBox(height: 8),
        Text(
          'To\'plangan ma\'lumotlar quyidagi maqsadlarda ishlatiladi:\n'
          '• Hisob yaratish va autentifikatsiya\n'
          '• Xona takliflari uchun push bildirishnomalar yuborish\n'
          '• Video tomosha sessiyasini sinxronlashtirish\n'
          '• Xizmat sifatini yaxshilash',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('4. Uchinchi tomon xizmatlari', style: heading),
        const SizedBox(height: 8),
        Text(
          'Biz quyidagi uchinchi tomon xizmatlaridan foydalanamiz:\n\n'
          '• Firebase (Google) — push bildirishnomalar va autentifikatsiya. '
          'Firebase\'ning maxfiylik siyosati: firebase.google.com/support/privacy\n\n'
          '• Render.com — backend server xizmati.\n\n'
          '• WebRTC — peer-to-peer ovozli aloqa (ma\'lumotlar server orqali o\'tmaydi).',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('5. Ma\'lumotlarni saqlash va himoya', style: heading),
        const SizedBox(height: 8),
        Text(
          'Barcha server aloqalari HTTPS/WSS orqali shifrlangan. '
          'Parollar bcrypt algoritmi bilan saqlanadi. '
          'Tokenlar qurilmada xavfsiz xotira (Keystore/Keychain) da saqlanadi. '
          'Foydalanuvchi ma\'lumotlari uchinchi tomonlarga sotilmaydi.',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('6. Foydalanuvchi huquqlari', style: heading),
        const SizedBox(height: 8),
        Text(
          'Siz istalgan vaqt:\n'
          '• Akkauntingizni o\'chirishingiz mumkin\n'
          '• Mikrofon/kamera ruxsatlarini qurilma sozlamalaridan bekor qilishingiz mumkin\n'
          '• Ma\'lumotlaringizni so\'rashingiz yoki o\'chirtirishingiz mumkin',
          style: style,
        ),
        const SizedBox(height: 20),

        Text('7. Bog\'lanish', style: heading),
        const SizedBox(height: 8),
        Text(
          'Savollar uchun: blacktaller5@gmail.com',
          style: style,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
