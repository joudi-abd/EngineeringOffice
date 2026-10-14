import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';

/// Pages ease in with a short fade and lift, never a hard cut.
class LuxRoute<T> extends PageRouteBuilder<T> {
  LuxRoute({required WidgetBuilder builder, super.settings, bool fade = false})
    : super(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Brand.ease,
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: curved,
            child: fade
                ? child
                : SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.035),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
          );
        },
      );
}
