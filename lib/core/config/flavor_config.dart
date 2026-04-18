import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build flavor. Each flavor loads its own `.env.<flavor>` file (falling
/// back to `.env` if the flavor-specific file is missing).
enum Flavor { dev, staging, prod }

/// Runtime configuration loaded from a dotenv file at boot. Every feature
/// reads network endpoints / toggles from here — never from hard-coded
/// constants — so the same binary can target different environments.
class FlavorConfig {
  FlavorConfig._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.apiFileUrl,
    required this.appName,
    required this.enableLogging,
  });

  final Flavor flavor;
  final String apiBaseUrl;
  final String apiFileUrl;
  final String appName;
  final bool enableLogging;

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('FlavorConfig.init() must be called before access.');
    }
    return i;
  }

  /// Loads the appropriate `.env.<flavor>` asset and caches a singleton.
  /// Safe to call once from [AppBootstrap]. Missing variables throw a
  /// StateError immediately so misconfiguration fails loud at boot instead
  /// of crashing deep inside a feature.
  static Future<void> init({required Flavor flavor}) async {
    final fileName = switch (flavor) {
      Flavor.dev => '.env.dev',
      Flavor.staging => '.env.staging',
      Flavor.prod => '.env.prod',
    };

    try {
      await dotenv.load(fileName: fileName);
    } catch (_) {
      // Fallback to the generic .env so local dev doesn't require a
      // flavor-specific file. Surfaces the same missing-variable error
      // below if that's also absent.
      await dotenv.load(fileName: '.env');
    }

    _instance = FlavorConfig._(
      flavor: flavor,
      apiBaseUrl: _require('API_BASE_URL'),
      apiFileUrl: _require('API_FILE_URL'),
      appName: dotenv.maybeGet('APP_NAME') ?? 'Digital Trade',
      enableLogging:
          (dotenv.maybeGet('ENABLE_LOGGING') ?? 'false').toLowerCase() ==
              'true',
    );
  }

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        '[FlavorConfig] Missing env variable "$key". '
        'Copy .env.example to .env and set all required keys.',
      );
    }
    return value;
  }

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
