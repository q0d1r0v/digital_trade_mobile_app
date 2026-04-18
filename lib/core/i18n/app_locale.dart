import 'package:flutter/widgets.dart';

/// Supported languages. Values mirror the asset filenames under
/// `assets/i18n/<code>.json`, so adding a new language is one JSON + one
/// enum entry.
enum AppLocale {
  uz('uz', "O'zbekcha", '🇺🇿'),
  ru('ru', 'Русский', '🇷🇺'),
  en('en', 'English', '🇬🇧');

  const AppLocale(this.code, this.displayName, this.flag);

  final String code;
  final String displayName;
  final String flag;

  Locale toFlutterLocale() => Locale(code);

  static AppLocale fromCode(String? code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.uz,
    );
  }
}
