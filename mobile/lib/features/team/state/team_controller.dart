import 'package:ufuq_imperium/core/state/localized_controller.dart';
import 'package:ufuq_imperium/features/team/data/team_member.dart';
import 'package:ufuq_imperium/features/team/data/team_repository.dart';

class TeamController extends LocalizedController {
  TeamController(this._repository, super.locale);
  final TeamRepository _repository;

  List<TeamMember> _items = const [];

  Future<bool> load() async {
    try {
      _items = await _repository.fetch();
      refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<TeamMember> get team => cached(
    'team',
    () => [
      for (final m in _items)
        m.copyWith(
          name: translator.name(m.name),
          jobTitle: translator.text(m.jobTitle),
          bio: translator.maybe(m.bio),
        ),
    ],
  );
}
