import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  EdgeInsets get safePadding => mq.padding;

  bool get isKeyboardOpen => mq.viewInsets.bottom > 0;

  void showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Multi-line validation errors from NestJS come joined by '\n';
          // letting the SnackBar grow vertically keeps them all readable.
          content: Text(message, maxLines: 8),
          backgroundColor: error ? colors.error : null,
          duration: error
              ? const Duration(seconds: 6)
              : const Duration(seconds: 3),
        ),
      );
  }

  /// Pops the current route if there's something to pop, otherwise
  /// navigates to [fallback] (default: home). Drawer entries use
  /// `context.go`, which replaces the stack — so form pages reached
  /// that way can't just call `context.safePop()` after save. This helper
  /// keeps call sites one-liner without the caller worrying about
  /// the navigation history.
  void safePop([String fallback = AppRoutes.home]) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
