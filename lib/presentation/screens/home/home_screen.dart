import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roomNameCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _createRoom() async {
    final name = _roomNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final room = await ApiService.createRoom(name);
      if (mounted) context.go('/room/${room.code}');
    } catch (_) {
      setState(() => _error = 'Xona yaratishda xatolik');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _joinCodeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = '6 ta belgili kod kiriting');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final room = await ApiService.joinRoom(code);
      if (mounted) context.go('/room/${room.code}');
    } catch (_) {
      setState(() => _error = 'Xona topilmadi. Kodni tekshiring');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clear();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _roomNameCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_rounded,
                color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('MovieSee'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white60),
            onPressed: _logout,
            tooltip: 'Chiqish',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.add_circle_outline_rounded,
              title: 'Yangi xona yaratish',
              child: Column(
                children: [
                  TextField(
                    controller: _roomNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Xona nomi',
                      prefixIcon: Icon(Icons.meeting_room_outlined,
                          color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _createRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('Xona yaratish'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.login_rounded,
              title: "Xonaga qo'shilish",
              child: Column(
                children: [
                  TextField(
                    controller: _joinCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Xona kodi (masalan: AB12CD)',
                      prefixIcon:
                          Icon(Icons.key_rounded, color: Colors.white38),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _joinRoom,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text("Qo'shilish"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 32),
            const _HowItWorksSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.link_rounded, 'Video URL kiriting (archive.org va h.k.)'),
      (Icons.share_rounded, 'Xona kodini do\'stingizga yuboring'),
      (Icons.play_circle_outline_rounded, 'Birgalikda tomosha qiling!'),
      (Icons.mic_rounded, 'Mikrofon orqali gaplashing'),
      (Icons.chat_bubble_outline_rounded, 'Chat orqali yozing'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qanday ishlaydi?',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(s.$1, color: Colors.white38, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(s.$2,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13))),
                ],
              ),
            )),
      ],
    );
  }
}
