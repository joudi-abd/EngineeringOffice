import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/features/shell/presentation/shell_scope.dart';
import 'package:ufuq_imperium/features/shell/presentation/widgets/site_footer.dart';

/// Scroll container shared by the five tabs: pull to refresh, footer, room for the bottom bar.
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.slivers, this.footer = true});
  final List<Widget> slivers;
  final bool footer;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final pal = context.pal;
    return RefreshIndicator(
      color: pal.accentSoft,
      backgroundColor: pal.bg2,
      strokeWidth: 1.6,
      edgeOffset: top + kBarHeight,
      onRefresh: ShellScope.of(context).refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...slivers,
          if (footer) const SliverToBoxAdapter(child: SiteFooter()),
        ],
      ),
    );
  }
}
