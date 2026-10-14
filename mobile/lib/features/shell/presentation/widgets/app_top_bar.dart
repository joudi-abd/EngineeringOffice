import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/theme_button.dart';
import 'package:ufuq_imperium/features/shell/presentation/widgets/brand_logo.dart';

/// Logo on one side, language switch on the other. Turns into frosted black once the page scrolls.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.solid, this.onLogoTap});
  final bool solid;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final top = MediaQuery.paddingOf(context).top;
    final pal = context.pal;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: solid ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      curve: Brand.ease,
      builder: (context, t, child) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
          child: Container(
            height: top + kBarHeight,
            padding: EdgeInsets.only(
              top: top,
              left: kGutter - 6,
              right: kGutter - 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    pal.bg.withValues(alpha: pal.dark ? 0.55 : 0.7),
                    pal.bg.withValues(alpha: 0.84),
                    t,
                  )!,
                  Color.lerp(
                    pal.bg.withValues(alpha: 0),
                    pal.bg.withValues(alpha: 0.84),
                    t,
                  )!,
                ],
              ),
              border: Border(
                bottom: BorderSide(color: pal.line.withValues(alpha: 0.5 * t)),
              ),
            ),
            child: child,
          ),
        ),
      ),
      child: Row(
        children: [
          // The logo gives way (scales down) before the buttons ever overflow on narrow screens.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLogoTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  child: Semantics(
                    label: locale.c.brand,
                    image: true,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: BrandLogo(height: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const BarActions(),
        ],
      ),
    );
  }
}
