import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/features/team/data/team_member.dart';

class TeamRepository {
  TeamRepository(this._api);
  final ApiClient _api;

  Future<List<TeamMember>> fetch() async =>
      (await _api.list('/team-members'))
          .map(TeamMember.fromJson)
          .where((m) => m.active)
          .toList();
}
