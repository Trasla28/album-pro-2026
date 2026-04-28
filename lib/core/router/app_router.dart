import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/notifications/notification_prefs_screen.dart';
import '../../presentation/screens/achievements/achievements_screen.dart';

// Signals when the splash animation has finished — prevents navigating away
// from splash before the 1.8s animation completes even if auth resolves faster.
final splashReadyProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: 'notification-prefs',
              builder: (_, __) => const NotificationPrefsScreen()),
          GoRoute(
              path: 'achievements',
              builder: (_, __) => const AchievementsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página no encontrada: ${state.error}')),
    ),
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Re-evaluate redirects whenever auth state or splash readiness changes.
    _ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<bool>(splashReadyProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final splashReady = _ref.read(splashReadyProvider);
    final location = state.matchedLocation;
    final onSplash = location == '/splash';
    final onAuthRoute = location == '/login' || location == '/register' || location.startsWith('/onboarding');

    // While loading: stay on splash for the initial app load.
    // But if the user is already on a login/onboarding screen (e.g. tapped
    // "Sign in with Google"), keep them there — don't redirect to splash.
    if (!splashReady || authAsync.isLoading) {
      if (authAsync.isLoading && onAuthRoute) return null;
      return onSplash ? null : '/splash';
    }

    final isAuthenticated = authAsync.valueOrNull?.isAuthenticated ?? false;

    if (onSplash) return isAuthenticated ? '/home' : '/onboarding';
    if (!isAuthenticated && !onAuthRoute) return '/login';
    if (isAuthenticated && onAuthRoute) return '/home';

    return null;
  }
}
