import 'package:flutter/foundation.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/localization/translator.dart';

/// Base for a feature's controller that shows content in the current language.
/// Localized getters are memoised and the cache is dropped whenever the language
/// or the translations change.
abstract class LocalizedController extends ChangeNotifier {
  LocalizedController(this.locale) {
    locale.addListener(refresh);
  }

  final LocaleController locale;
  final Map<String, Object?> _memo = {};

  Translator get translator => locale.translator;

  @protected
  T cached<T>(String key, T Function() build) {
    final hit = _memo[key];
    if (hit is T) return hit;
    final value = build();
    _memo[key] = value;
    return value;
  }

  /// Drops memoised values and tells listeners to rebuild.
  @protected
  void refresh() {
    _memo.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    locale.removeListener(refresh);
    super.dispose();
  }
}
