import 'package:flutter/material.dart';

import '../../../../core/widgets/app_loader.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: AppLoader());
}
