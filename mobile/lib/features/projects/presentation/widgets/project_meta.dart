import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';

/// Place · year line used under project titles.
class ProjectMeta extends StatelessWidget {
  const ProjectMeta({super.key, required this.project, this.color});
  final Project project;

  /// Defaults to the soft gold of the current look; pass a fixed colour when laid over a photograph.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final parts = <String>[
      if ((project.location ?? '').isNotEmpty) project.location!,
      if (project.year != null) '${project.year}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.map((p) => tracked(context, p)).join('  ·  '),
      style: type.meta(color: color),
    );
  }
}
