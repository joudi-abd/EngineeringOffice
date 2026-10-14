import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/features/settings/data/setting.dart';

class SettingsRepository {
  SettingsRepository(this._api);
  final ApiClient _api;

  Future<List<Setting>> fetch() async =>
      (await _api.list('/settings')).map(Setting.fromJson).toList();
}
