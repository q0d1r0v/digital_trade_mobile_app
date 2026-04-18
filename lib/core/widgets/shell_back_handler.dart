import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';

/// Normalises the Android hardware / gesture "back" behaviour across the
/// app:
///   1. If go_router has a previous route on the stack → `pop()`
///      (standard "previous page" behaviour).
///   2. Else if we're anywhere but home → `go('/home')`
///      (drawer `go` calls clear the stack, so without this the back
///      button would quit the app from e.g. /cashboxes).
///   3. Else (we are already on home) → fall through to the platform
///      default, which collapses the app to the task switcher.
///
/// Wrap every top-level Scaffold body with this — the scaffold's
/// AppBar back-arrow still works because `canPop()` also checks the
/// go_router stack.
class ShellBackHandler extends StatelessWidget {
  const ShellBackHandler({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        final location = GoRouterState.of(context).matchedLocation;
        if (location != AppRoutes.home) {
          context.go(AppRoutes.home);
          return;
        }
        // Home + no stack → defer to the OS (move to background).
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}
