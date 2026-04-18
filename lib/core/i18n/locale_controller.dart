import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../di/injection.dart';
import 'app_locale.dart';
import 'app_translations.dart';

/// Current locale. Persisted in SharedPreferences so the user's choice
/// survives restarts. Defaults to Uzbek on first launch — matches the
/// primary market.
class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    final prefs = sl<SharedPreferences>();
    return AppLocale.fromCode(prefs.getString(StorageKeys.locale));
  }

  Future<void> set(AppLocale locale) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setString(StorageKeys.locale, locale.code);
    state = locale;
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

/// Async provider that loads the JSON bundle for the current locale.
/// Feature widgets watch this via `ref.watch(translationsProvider).value`
/// and use a tiny extension (`context.t('...')`) to keep call sites short.
final translationsProvider = FutureProvider<AppTranslations>((ref) async {
  final locale = ref.watch(localeControllerProvider);
  return AppTranslations.load(locale);
});
