import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/build_config.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/api_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/session/session_screen.dart';
import '../screens/feedback/feedback_screen.dart';
import '../screens/review/review_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasKeyAsync = ref.watch(hasApiKeyProvider);
  final hasKey = hasKeyAsync.value ?? false;
  final initialLocation = BuildConfig.requiresApiKey
      ? (hasKey ? '/' : '/onboarding')
      : '/';
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/api-setup',
        builder: (context, state) => const ApiSetupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SessionScreen(
            topic: extra?['topic'] as String? ?? 'daily',
            level: extra?['level'] as String? ?? 'A1',
          );
        },
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return FeedbackScreen(
            evaluation: extra['evaluation'],
            userAnswer: extra['userAnswer'] as String,
            question: extra['question'],
          );
        },
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
