import 'package:flutter/foundation.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/features/projects/state/projects_controller.dart';
import 'package:ufuq_imperium/features/services/state/services_controller.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';
import 'package:ufuq_imperium/features/team/state/team_controller.dart';

enum LoadState { loading, ready, failed }

/// Starts the app and keeps the public content fresh: restores the language, then loads
/// every feature's data in parallel. It is "failed" only when nothing could be reached
/// (offline, server down) and there is nothing cached from an earlier load.
class SiteBootstrap extends ChangeNotifier {
  SiteBootstrap({
    required this.locale,
    required this.settings,
    required this.services,
    required this.projects,
    required this.team,
  });

  final LocaleController locale;
  final SettingsController settings;
  final ServicesController services;
  final ProjectsController projects;
  final TeamController team;

  LoadState _state = LoadState.loading;
  bool _hasData = false;

  LoadState get state => _state;
  bool get hasData => _hasData;

  Future<void> start() async {
    await locale.start();
    await load();
  }

  Future<void> load() async {
    if (!_hasData) {
      _state = LoadState.loading;
      notifyListeners();
    }
    final results = await Future.wait([
      settings.load(),
      services.load(),
      projects.load(),
      team.load(),
    ]);
    if (results.any((ok) => ok)) _hasData = true;
    _state = _hasData ? LoadState.ready : LoadState.failed;
    notifyListeners();
  }
}
