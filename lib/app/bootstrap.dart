import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/config/flavor_config.dart';
import '../core/di/injection.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

/// Centralised start-up sequence. Any cross-cutting init (Sentry, Firebase,
/// analytics, crash reporting, hive.registerAdapter, etc.) lives here.
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> run({
    required Flavor flavor,
    required Widget Function() buildApp,
  }) async {
    await runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();

      await FlavorConfig.init(flavor: flavor);
      await configureDependencies();

      // Wire the refresh interceptor's "auth failed" hook into the auth
      // repository so a failed refresh clears the session AND emits on
      // `authStateChanges` — the router listens to that stream and will
      // redirect to /login automatically.
      setAuthFailedCallback(() async {
        await sl<AuthRepository>().clearSession();
      });

      runApp(buildApp());
    }, (error, stack) {
      // Swap for Sentry / Crashlytics once wired.
      debugPrint('Uncaught: $error\n$stack');
    });
  }
}
