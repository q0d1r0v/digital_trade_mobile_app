import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/onboarding_probe_service.dart';
import '../../domain/entities/onboarding_task.dart';

final onboardingProbeServiceProvider = Provider<OnboardingProbeService>(
  (ref) => OnboardingProbeService(sl<ApiClient>()),
);

/// Evaluates every probe once per invalidation. Widgets call
/// `ref.invalidate(onboardingProgressProvider)` after creating a resource
/// to recompute the checklist — this matches the frontend's
/// `onResourceCreated` bus.
final onboardingProgressProvider =
    FutureProvider<Map<OnboardingProbe, bool>>((ref) async {
  // Only run probes for authenticated users.
  final authAsync = ref.watch(authStateProvider);
  final isAuthed = authAsync.maybeWhen(data: (v) => v, orElse: () => false);
  if (!isAuthed) return const {};

  final service = ref.watch(onboardingProbeServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  return service.evaluate(user);
});

/// Has the user dismissed the checklist FAB? Persisted so it doesn't
/// reappear on every cold start.
class OnboardingDismissController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = sl<SharedPreferences>();
    return prefs.getBool(StorageKeys.onboardingDismissed) ?? false;
  }

  Future<void> setDismissed(bool value) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(StorageKeys.onboardingDismissed, value);
    state = value;
  }
}

final onboardingDismissedProvider =
    NotifierProvider<OnboardingDismissController, bool>(
  OnboardingDismissController.new,
);

/// Has the welcome modal been shown to this user? Persists across
/// restarts but resets on logout/register.
class WelcomeSeenController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = sl<SharedPreferences>();
    return prefs.getBool(StorageKeys.onboardingWelcomeSeen) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(StorageKeys.onboardingWelcomeSeen, true);
    state = true;
  }

  Future<void> reset() async {
    final prefs = sl<SharedPreferences>();
    await prefs.remove(StorageKeys.onboardingWelcomeSeen);
    await prefs.remove(StorageKeys.onboardingDismissed);
    state = false;
  }
}

final welcomeSeenProvider =
    NotifierProvider<WelcomeSeenController, bool>(WelcomeSeenController.new);
