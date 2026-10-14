import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/app/site_bootstrap.dart';
import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/core/theme/theme_controller.dart';
import 'package:ufuq_imperium/features/contact/data/contact_repository.dart';
import 'package:ufuq_imperium/features/projects/data/projects_repository.dart';
import 'package:ufuq_imperium/features/projects/state/projects_controller.dart';
import 'package:ufuq_imperium/features/services/data/services_repository.dart';
import 'package:ufuq_imperium/features/services/state/services_controller.dart';
import 'package:ufuq_imperium/features/settings/data/settings_repository.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';
import 'package:ufuq_imperium/features/team/data/team_repository.dart';
import 'package:ufuq_imperium/features/team/state/team_controller.dart';

/// Wires the app together: one API client, a repository and a controller per feature.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, api) => api.close(),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController()..start(),
        ),

        // data
        Provider<SettingsRepository>(
          create: (c) => SettingsRepository(c.read<ApiClient>()),
        ),
        Provider<ServicesRepository>(
          create: (c) => ServicesRepository(c.read<ApiClient>()),
        ),
        Provider<ProjectsRepository>(
          create: (c) => ProjectsRepository(c.read<ApiClient>()),
        ),
        Provider<TeamRepository>(
          create: (c) => TeamRepository(c.read<ApiClient>()),
        ),
        Provider<ContactRepository>(
          create: (c) => ContactRepository(c.read<ApiClient>()),
        ),

        // state
        ChangeNotifierProvider<SettingsController>(
          create: (c) => SettingsController(
            c.read<SettingsRepository>(),
            c.read<LocaleController>(),
          ),
        ),
        ChangeNotifierProvider<ServicesController>(
          create: (c) => ServicesController(
            c.read<ServicesRepository>(),
            c.read<LocaleController>(),
          ),
        ),
        ChangeNotifierProvider<ProjectsController>(
          create: (c) => ProjectsController(
            c.read<ProjectsRepository>(),
            c.read<LocaleController>(),
          ),
        ),
        ChangeNotifierProvider<TeamController>(
          create: (c) => TeamController(
            c.read<TeamRepository>(),
            c.read<LocaleController>(),
          ),
        ),
        ChangeNotifierProvider<SiteBootstrap>(
          create: (c) => SiteBootstrap(
            locale: c.read<LocaleController>(),
            settings: c.read<SettingsController>(),
            services: c.read<ServicesController>(),
            projects: c.read<ProjectsController>(),
            team: c.read<TeamController>(),
          )..start(),
        ),
      ],
      child: child,
    );
  }
}
