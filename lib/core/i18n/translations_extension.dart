import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_translations.dart';
import 'locale_controller.dart';

/// `ref.t('path.to.key')` — terse lookup from inside `ConsumerWidget` /
/// `ConsumerStatefulWidget` build methods. Returns the raw path if
/// translations haven't finished loading yet (first frame only), which is
/// harmless: the widget rebuilds once the future resolves.
extension TranslationsWidgetRefX on WidgetRef {
  String t(String path, {Map<String, Object?>? params}) {
    final async = watch(translationsProvider);
    final AppTranslations? value = async.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    return value?.t(path, params: params) ?? path;
  }
}
