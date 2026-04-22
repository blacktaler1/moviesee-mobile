import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await StorageService.saveToken(res['access_token'] as String);
      await StorageService.saveUser(
          UserModel.fromJson(res['user'] as Map<String, dynamic>));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Email yoki parol noto\'g\'ri');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Icon(Icons.movie_filter_rounded,
                    size: 64, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('MovieSee',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 48),
              Text('Kirish',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 24),
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
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kirish'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Akkaunt yo'qmi? Ro'yxatdan o'tish",
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
