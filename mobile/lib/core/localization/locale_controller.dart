import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ufuq_imperium/core/localization/copy.dart';
import 'package:ufuq_imperium/core/localization/translator.dart';

/// The app language (Arabic / English), its UI strings, and the on-the-fly translator for content.
/// Notifies on a language switch and whenever new translations arrive.
class LocaleController extends ChangeNotifier {
  LocaleController({Translator? translator})
    : translator = translator ?? Translator() {
    this.translator.addListener(notifyListeners);
  }

  static const _prefsKey = 'ufuq-lang';

  final Translator translator;
  Lang _lang = Lang.ar;

  Lang get lang => _lang;
  bool get isArabic => _lang == Lang.ar;
  Copy get c => Copy.of(_lang);

  /// Restores the saved language and the translation cache.
  Future<void> start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lang = prefs.getString(_prefsKey) == 'en' ? Lang.en : Lang.ar;
      translator.lang = _lang;
    } catch (_) {}
    await translator.restore();
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _lang = _lang == Lang.ar ? Lang.en : Lang.ar;
    translator.lang = _lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _lang.name);
    } catch (_) {}
  }

  @override
  void dispose() {
    translator.removeListener(notifyListeners);
    translator.dispose();
    super.dispose();
  }
}
