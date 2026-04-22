import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final token = await StorageService.getToken();
    if (token != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_rounded,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('MovieSee',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Birgalikda tomosha qiling',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
