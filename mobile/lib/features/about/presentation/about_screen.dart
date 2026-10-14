import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/page_blocks.dart';
import 'package:ufuq_imperium/core/widgets/point_row.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/features/services/presentation/widgets/service_row.dart';
import 'package:ufuq_imperium/features/services/state/services_controller.dart';
import 'package:ufuq_imperium/features/shell/presentation/shell_scope.dart';
import 'package:ufuq_imperium/features/shell/presentation/tab_page.dart';
import 'package:ufuq_imperium/features/team/presentation/widgets/member_card.dart';
import 'package:ufuq_imperium/features/team/state/team_controller.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = context.watch<LocaleController>();
    final servicesCtl = context.watch<ServicesController>();
    final teamCtl = context.watch<TeamController>();
    final c = locale.c;
    final type = context.type;
    final shell = ShellScope.of(context);
    final services = servicesCtl.services;
    final team = teamCtl.team;

    return TabPage(
      slivers: [
        SliverToBoxAdapter(
          child: PageIntro(
            kicker: c.tabs[1],
            title: c.aboutPageTitle,
            lede: c.aboutPageLede,
          ),
        ),

        // story
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 70, kGutter, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(child: Kicker(c.storyEyebrow, index: '01')),
                const SizedBox(height: 24),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Display(c.storyTitle),
                ),
                const SizedBox(height: 26),
                for (var i = 0; i < c.story.length; i++)
                  Reveal(
                    delay: Duration(milliseconds: 140 + i * 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(c.story[i], style: type.body(size: 16)),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // vision & mission
        SliverToBoxAdapter(
          child: Container(
            color: pal.bg2,
            padding: const EdgeInsets.fromLTRB(kGutter, 64, kGutter, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Aim(kicker: c.visionEyebrow, text: c.vision),
                const SizedBox(height: 46),
                _Aim(kicker: c.missionEyebrow, text: c.mission),
              ],
            ),
          ),
        ),

        // values
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 80, kGutter, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(child: Kicker(c.valuesEyebrow, index: '02')),
                const SizedBox(height: 24),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Display(c.valuesTitle),
                ),
                const SizedBox(height: 40),
                for (final value in c.values) PointRow(point: value),
              ],
            ),
          ),
        ),

        // fields of work
        if (services.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: pal.bg2,
              padding: const EdgeInsets.fromLTRB(kGutter, 80, kGutter, 70),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(child: Kicker(c.fieldsEyebrow, index: '03')),
                  const SizedBox(height: 24),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: Display(c.fieldsTitle),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: const Duration(milliseconds: 140),
                    child: Text(c.fieldsLede, style: type.body()),
                  ),
                  const SizedBox(height: 34),
                  for (var i = 0; i < services.length; i++)
                    ServiceRow(index: i + 1, service: services[i]),
                  Container(height: 1, color: pal.line),
                ],
              ),
            ),
          ),

        // team
        if (team.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kGutter, 80, kGutter, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(
                    child: Kicker(
                      c.teamEyebrow,
                      index: services.isNotEmpty ? '04' : '03',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: Display(c.teamTitle),
                  ),
                  const SizedBox(height: 34),
                  for (final member in team)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Reveal(child: MemberCard(member: member)),
                    ),
                ],
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: PageNext(
            title: c.aboutNext,
            links: [
              (label: c.tabs[3], onTap: () => shell.goTo(3)),
              (label: c.contactEyebrow, onTap: () => shell.goTo(4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Aim extends StatelessWidget {
  const _Aim({required this.kicker, required this.text});
  final String kicker;
  final String text;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Hairline(),
          const SizedBox(height: 26),
          Kicker(kicker),
          const SizedBox(height: 20),
          Text(text, style: type.display(type.ar ? 25 : 28)),
        ],
      ),
    );
  }
}
