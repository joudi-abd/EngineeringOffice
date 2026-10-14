import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/theme_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/circle_button.dart';
import 'package:ufuq_imperium/core/widgets/lang_button.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';

/// Day / night switch. Shows the sun while the app is dark (press for day) and the moon while it
/// is light (press for night). Pressing it makes the choice stick; pressing again so it matches the phone
/// again hands control back to the phone. Until the first press the app follows the phone.
class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.pal.dark;
    final c = context.watch<LocaleController>().c;
    return CircleButton(
      semanticLabel: dark ? c.themeToLight : c.themeToDark,
      onTap: () => context.read<ThemeController>().toggle(
        currentlyDark: dark,
        systemDark: MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      ),
      builder: (context, ink) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Brand.ease,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween(begin: -0.25, end: 0.0).animate(animation),
          child: ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
        child: PathIcon(
          dark ? Glyphs.sun : Glyphs.moon,
          key: ValueKey(dark),
          size: 21,
          color: ink,
          strokeWidth: 1.45,
        ),
      ),
    );
  }
}

/// The two round buttons that sit at the end of the top bars.
class BarActions extends StatelessWidget {
  const BarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeButton(),
        const SizedBox(width: 6),
        LangButton(label: locale.c.langSwitch, onTap: locale.toggleLanguage),
      ],
    );
  }
}
