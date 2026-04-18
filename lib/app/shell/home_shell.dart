import 'package:flutter/material.dart';

/// Shell wrapper for tab-level pages. Left intentionally thin — the
/// navigation UI is provided by [AppDrawer] on each page's Scaffold,
/// which lets pages keep their AppBar titles/actions intact. The shell
/// still exists so go_router has a place to hang tab-level routes.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
