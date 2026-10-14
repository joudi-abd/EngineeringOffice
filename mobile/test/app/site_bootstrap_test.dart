import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ufuq_imperium/app/site_bootstrap.dart';
import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/features/projects/data/projects_repository.dart';
import 'package:ufuq_imperium/features/projects/state/projects_controller.dart';
import 'package:ufuq_imperium/features/services/data/services_repository.dart';
import 'package:ufuq_imperium/features/services/state/services_controller.dart';
import 'package:ufuq_imperium/features/settings/data/settings_repository.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';
import 'package:ufuq_imperium/features/team/data/team_repository.dart';
import 'package:ufuq_imperium/features/team/state/team_controller.dart';

SiteBootstrap _site(Future<http.Response> Function(http.Request) handler) {
  final api = ApiClient(client: MockClient(handler));
  final locale = LocaleController();
  return SiteBootstrap(
    locale: locale,
    settings: SettingsController(SettingsRepository(api), locale),
    services: ServicesController(ServicesRepository(api), locale),
    projects: ProjectsController(ProjectsRepository(api), locale),
    team: TeamController(TeamRepository(api), locale),
  );
}

void main() {
  test('is failed only when every endpoint is unreachable', () async {
    final site = _site((_) async => throw http.ClientException('offline'));
    await site.load();
    expect(site.state, LoadState.failed);
    expect(site.hasData, isFalse);
  });

  test(
    'is ready as soon as one endpoint answers, and localizes content',
    () async {
      final site = _site((request) async {
        if (request.url.path.endsWith('/services')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 1,
                  'name': 'Planning',
                  'slug': 'planning',
                  'is_active': 1,
                },
                {'id': 2, 'name': 'Hidden', 'slug': 'hidden', 'is_active': 0},
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 500);
      });
      await site.load();
      expect(site.state, LoadState.ready);
      expect(site.hasData, isTrue);
      expect(site.services.services.map((s) => s.name), ['Planning']);
    },
  );
}
