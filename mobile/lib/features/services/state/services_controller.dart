import 'package:ufuq_imperium/core/state/localized_controller.dart';
import 'package:ufuq_imperium/features/services/data/service.dart';
import 'package:ufuq_imperium/features/services/data/services_repository.dart';
import 'package:ufuq_imperium/features/services/state/service_localizer.dart';

class ServicesController extends LocalizedController {
  ServicesController(this._repository, super.locale);
  final ServicesRepository _repository;

  List<Service> _items = const [];

  Future<bool> load() async {
    try {
      _items = await _repository.fetch();
      refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Service> get services => cached(
    'services',
    () => [for (final item in _items) item.localized(translator)],
  );
}
