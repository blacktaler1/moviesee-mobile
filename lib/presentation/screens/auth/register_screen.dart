import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = "Barcha maydonlarni to'ldiring");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await StorageService.saveToken(res['access_token'] as String);
      await StorageService.saveUser(
          UserModel.fromJson(res['user'] as Map<String, dynamic>));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() =>
          _error = "Ro'yxatdan o'tishda xatolik. Email band bo'lishi mumkin.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ro'yxatdan o'tish")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _usernameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Foydalanuvchi nomi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Parol'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("Ro'yxatdan o'tish"),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Akkaunt bor? Kirish',
                      style: TextStyle(color: Colors.white60)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/privacy-policy'),
                  child: const Text(
                    'Maxfiylik siyosati',
                    style: TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
