import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/notification_service.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/room/player_screen.dart';
import '../../presentation/screens/privacy_policy_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final token = await StorageService.getToken();
      final isAuth = token != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/';
      final isPublic = state.matchedLocation == '/privacy-policy';

      if (isSplash || isPublic) return null;
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(
        path: '/room/:code',
        builder: (context, state) => PlayerScreen(
          roomCode: state.pathParameters['code']!,
        ),
      ),
    ],
  );
});
