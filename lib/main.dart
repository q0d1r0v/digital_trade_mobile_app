import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/config/flavor_config.dart';

Future<void> main() => AppBootstrap.run(
      flavor: Flavor.dev,
      buildApp: () => const ProviderScope(child: DigitalTradeApp()),
    );
