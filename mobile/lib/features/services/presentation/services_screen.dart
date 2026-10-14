import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/page_blocks.dart';
import 'package:ufuq_imperium/core/widgets/states.dart';
import 'package:ufuq_imperium/features/services/presentation/widgets/service_row.dart';
import 'package:ufuq_imperium/features/services/state/services_controller.dart';
import 'package:ufuq_imperium/features/shell/presentation/shell_scope.dart';
import 'package:ufuq_imperium/features/shell/presentation/tab_page.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = context.watch<LocaleController>();
    final servicesCtl = context.watch<ServicesController>();
    final c = locale.c;
    final shell = ShellScope.of(context);
    final services = servicesCtl.services;

    return TabPage(
      slivers: [
        SliverToBoxAdapter(
          child: PageIntro(
            kicker: c.servicesEyebrow,
            title: c.servicesPageTitle,
            lede: c.servicesPageLede,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 70),
            child: services.isEmpty
                ? EmptyNote(c.servicesEmpty)
                : Column(
                    children: [
                      for (var i = 0; i < services.length; i++)
                        ServiceRow(
                          index: i + 1,
                          service: services[i],
                          full: true,
                        ),
                      Container(height: 1, color: pal.line),
                    ],
                  ),
          ),
        ),
        // SliverToBoxAdapter(
        //   child: PageNext(
        //     title: c.servicesNext,
        //     links: [
        //       (label: c.tabs[3], onTap: () => shell.goTo(3)),
        //       (label: c.contactEyebrow, onTap: () => shell.goTo(4)),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
