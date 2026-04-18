import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/flavor_config.dart';
import '../core/i18n/app_locale.dart';
import '../core/i18n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/plans/presentation/widgets/plan_status_gate.dart';
import 'router/app_router.dart';

class DigitalTradeApp extends ConsumerWidget {
  const DigitalTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: locale.toFlutterLocale(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocale.values.map((l) => l.toFlutterLocale()),
      // Every route rendered by go_router flows through this builder,
      // so the plan-status gate can cover the whole app — every screen,
      // every navigation — with a single wrapper instead of being
      // copy-pasted per page.
      builder: (context, child) =>
          PlanStatusGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
