import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/features/shell/presentation/shell_scope.dart';
import 'package:ufuq_imperium/features/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:ufuq_imperium/features/shell/presentation/widgets/app_top_bar.dart';

/// The app frame: a fixed top bar and bottom nav around the five tab pages.
/// The pages are handed in by the app layer, so the shell knows nothing about the features.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages, required this.onRefresh});

  /// Exactly five pages, in the order of the bottom bar tabs.
  final List<Widget> pages;
  final Future<void> Function() onRefresh;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> implements ShellActions {
  static const _tabs = 5;
  final List<ScrollController> _controllers = List.generate(
    _tabs,
    (_) => ScrollController(),
  );
  final ValueNotifier<bool> _solid = ValueNotifier(false);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _tabs; i++) {
      _controllers[i].addListener(() {
        if (i == _index) _syncSolid();
      });
    }
  }

  @override
  ScrollController get homeScroll => _controllers[0];

  void _syncSolid() {
    final c = _controllers[_index];
    _solid.value = c.hasClients && c.offset > 36;
  }

  @override
  void goTo(int index) {
    if (index == _index) {
      scrollToTop();
      return;
    }
    setState(() => _index = index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSolid());
  }

  @override
  void scrollToTop() {
    final c = _controllers[_index];
    if (!c.hasClients) return;
    c.animateTo(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Brand.ease,
    );
  }

  @override
  Future<void> refresh() => widget.onRefresh();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _solid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.watch<LocaleController>().c.tabs;
    final screens = widget.pages;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goTo(0);
      },
      child: ShellScope(
        actions: this,
        child: Scaffold(
          backgroundColor: context.pal.bg,
          body: Stack(
            children: [
              IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < _tabs; i++)
                    PrimaryScrollController(
                      controller: _controllers[i],
                      // every platform, so desktop/web previews behave exactly like the phone
                      automaticallyInheritForPlatforms: TargetPlatform.values
                          .toSet(),
                      child: screens[i],
                    ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _solid,
                  builder: (_, solid, _) =>
                      AppTopBar(solid: solid, onLogoTap: () => goTo(0)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(
                  index: _index,
                  labels: labels,
                  onSelect: goTo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
