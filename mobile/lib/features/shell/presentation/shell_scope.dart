import 'package:flutter/material.dart';

/// What the tabs can ask of the shell: switch tab, scroll, refresh the content.
abstract interface class ShellActions {
  void goTo(int index);
  void scrollToTop();

  /// The home page's scroll position (drives the hero parallax).
  ScrollController get homeScroll;

  /// Pull-to-refresh: reloads the public content.
  Future<void> refresh();
}

/// Lets any tab reach the shell without knowing about it.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.actions, required super.child});
  final ShellActions actions;

  static ShellActions of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()!.actions;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}
