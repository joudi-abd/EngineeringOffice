import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/widgets/lux_route.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/presentation/project_detail_screen.dart';

void openProject(BuildContext context, Project project, String heroTag) {
  Navigator.of(context).push(
    LuxRoute<void>(
      builder: (_) => ProjectDetailScreen(summary: project, heroTag: heroTag),
    ),
  );
}
