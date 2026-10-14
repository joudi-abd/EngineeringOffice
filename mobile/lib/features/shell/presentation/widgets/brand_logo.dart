import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';

/// The office logo: the one uploaded in the dashboard, else the built-in artwork for the language.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 30, this.compact = true});
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final settings = context.watch<SettingsController>();
    // The light artwork is for the black look, the dark artwork for the beige one.
    final tone = context.pal.dark ? 'light' : 'dark';
    final asset = locale.isArabic
        ? 'assets/brand/logo-ar-$tone.png'
        : (compact
              ? 'assets/brand/logo-en-$tone-compact.png'
              : 'assets/brand/logo-en-$tone.png');
    final fallback = Image.asset(asset, height: height, fit: BoxFit.contain);
    final remote = settings.logoUrl;
    // An uploaded logo is only shown on black: its colours are unknown, so on beige the
    // built-in dark artwork is used to keep it legible.
    if (remote.isEmpty || !context.pal.dark) return fallback;
    return CachedNetworkImage(
      imageUrl: remote,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, _) => SizedBox(height: height),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
