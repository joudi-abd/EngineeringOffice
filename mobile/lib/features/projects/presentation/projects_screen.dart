import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/page_blocks.dart';
import 'package:ufuq_imperium/core/widgets/states.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/presentation/open_project.dart';
import 'package:ufuq_imperium/features/projects/presentation/widgets/project_card.dart';
import 'package:ufuq_imperium/features/projects/state/projects_controller.dart';
import 'package:ufuq_imperium/features/shell/presentation/shell_scope.dart';
import 'package:ufuq_imperium/features/shell/presentation/tab_page.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final projectsCtl = context.watch<ProjectsController>();
    final c = locale.c;
    final shell = ShellScope.of(context);
    final categories = projectsCtl.categories;
    final visible = [
      for (final p in projectsCtl.projects)
        if (_filter == null || p.category?.id == _filter) p,
    ];

    return TabPage(
      slivers: [
        SliverToBoxAdapter(
          child: PageIntro(
            kicker: c.tabs[3],
            title: c.projectsPageTitle,
            lede: c.projectsPageLede,
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (categories.isNotEmpty)
                SizedBox(
                  height: 56,
                  child: Semantics(
                    label: c.filterLabel,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: kGutter),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _Chip(
                          label: c.all,
                          active: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final category in categories)
                          _Chip(
                            label: category.name,
                            active: _filter == category.id,
                            onTap: () => setState(() => _filter = category.id),
                          ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(kGutter, 26, kGutter, 70),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Brand.ease,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: visible.isEmpty
                      ? EmptyNote(c.projectsPageEmpty)
                      : Column(
                          key: ValueKey(_filter),
                          children: [
                            for (final Project project in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 52),
                                child: ProjectCard(
                                  project: project,
                                  heroTag: 'list-cover-${project.id}',
                                  onTap: () => openProject(
                                    context,
                                    project,
                                    'list-cover-${project.id}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        // SliverToBoxAdapter(
        //   child: PageNext(
        //     title: c.projectsNext,
        //     links: [(label: c.contactEyebrow, onTap: () => shell.goTo(4))],
        //   ),
        // ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 10, top: 4, bottom: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Brand.ease,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? pal.accent.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(color: active ? pal.accent : pal.line),
          ),
          child: Text(
            tracked(context, label),
            style: type
                .label(
                  color: active ? pal.accentSoft : pal.muted,
                  size: type.ar ? 15 : 11,
                )
                .copyWith(letterSpacing: type.ar ? 0 : 1.6),
          ),
        ),
      ),
    );
  }
}
