import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/features/services/data/service.dart';

class ServicesRepository {
  ServicesRepository(this._api);
  final ApiClient _api;

  Future<List<Service>> fetch() async =>
      (await _api.list('/services'))
          .map(Service.fromJson)
          .where((s) => s.active)
          .toList();
}
