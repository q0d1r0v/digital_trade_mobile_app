import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_locale.dart';

/// Minimal asset-based i18n. Loads `assets/i18n/<locale>.json` once, then
/// exposes `t('path.to.key', {param: value})` for dot-path lookup with
/// `{{name}}` interpolation.
///
/// Keeping this in-house (vs. easy_localization / intl codegen) means we
/// don't pull heavy dependencies for a 3-language CRUD app, and the JSON
/// files can stay 1:1 with the web frontend's locale files.
class AppTranslations {
  AppTranslations._(this._locale, this._data);

  final AppLocale _locale;
  final Map<String, dynamic> _data;

  AppLocale get locale => _locale;

  /// Loads the JSON file for [locale]. On parse error returns an empty map
  /// — the caller renders raw keys rather than crashing the app.
  static Future<AppTranslations> load(AppLocale locale) async {
    try {
      final raw = await rootBundle.loadString('assets/i18n/${locale.code}.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppTranslations._(locale, map);
    } catch (e, s) {
      debugPrint('[i18n] failed to load ${locale.code}: $e\n$s');
      return AppTranslations._(locale, const {});
    }
  }

  /// Dot-path lookup. Missing keys fall back to the raw path so the error
  /// is obvious in-app rather than silently blank.
  String t(String path, {Map<String, Object?>? params}) {
    final parts = path.split('.');
    dynamic cursor = _data;
    for (final part in parts) {
      if (cursor is Map<String, dynamic> && cursor.containsKey(part)) {
        cursor = cursor[part];
      } else {
        return path;
      }
    }
    if (cursor is! String) return path;
    if (params == null || params.isEmpty) return cursor;
    return _interpolate(cursor, params);
  }

  String _interpolate(String template, Map<String, Object?> params) {
    return template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (m) => params[m.group(1)]?.toString() ?? m.group(0)!,
    );
  }
}
