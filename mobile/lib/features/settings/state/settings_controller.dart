import 'package:ufuq_imperium/core/state/localized_controller.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/features/settings/data/setting.dart';
import 'package:ufuq_imperium/features/settings/data/settings_repository.dart';
import 'package:ufuq_imperium/features/settings/data/social.dart';

/// Settings whose values are identifiers (numbers, links) and must never be translated.
const _rawSettings = {
  'phone',
  'email',
  'whatsapp',
  'logo',
  'facebook',
  'instagram',
  'company_name',
};

/// Office details managed in the dashboard: contact lines, logo, social accounts.
class SettingsController extends LocalizedController {
  SettingsController(this._repository, super.locale);
  final SettingsRepository _repository;

  List<Setting> _items = const [];

  /// True when the request succeeded.
  Future<bool> load() async {
    try {
      _items = await _repository.fetch();
      refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  String setting(String key) {
    for (final item in _items) {
      if (item.key != key) continue;
      final raw = item.value?.trim() ?? '';
      return _rawSettings.contains(key) ? raw : translator.text(raw);
    }
    return '';
  }

  String get phone => setting('phone');
  String get email => setting('email');
  String get whatsapp => setting('whatsapp');
  String get address => setting('address');
  String get hours => setting('hours');
  String get companyName => setting('company_name');

  /// Logo uploaded in the dashboard; empty when none, so the built-in artwork is used.
  String get logoUrl => mediaUrl(setting('logo'));

  List<Social> get social => cached('social', () {
    final items = [
      Social(
        'facebook',
        'Facebook',
        socialLink(setting('facebook'), 'https://www.facebook.com/'),
      ),
      Social(
        'instagram',
        'Instagram',
        socialLink(setting('instagram'), 'https://www.instagram.com/'),
      ),
    ];
    return items.where((item) => item.href.isNotEmpty).toList();
  });
}
