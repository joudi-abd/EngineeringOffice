import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';

/// Type scale. Arabic uses Bukra with generous leading; English uses Neue Power with tracking.
class AppType {
  const AppType(this.ar, [this.pal = Palette.night]);
  final bool ar;

  /// Default text colours follow the day / night look.
  final Palette pal;

  static AppType of(BuildContext context) =>
      AppType(Directionality.of(context) == TextDirection.rtl, context.pal);

  String get family => ar ? 'Bukra' : 'NeuePower';
  String get fallback => ar ? 'NeuePower' : 'Bukra';

  TextStyle _base({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: [fallback],
    fontSize: size,
    fontWeight: weight,
    color: color ?? pal.text,
    height: height,
    letterSpacing: ar ? 0 : spacing,
  );

  /// Large section headings.
  TextStyle display([double? size]) => _base(
    size: size ?? (ar ? 29 : 33),
    weight: FontWeight.w500,
    height: ar ? 1.65 : 1.2,
  );

  /// Page headline (hero of an inner page).
  TextStyle headline([double? size]) => _base(
    size: size ?? (ar ? 32 : 40),
    weight: FontWeight.w500,
    height: ar ? 1.6 : 1.12,
  );

  TextStyle title([double? size]) => _base(
    size: size ?? (ar ? 22 : 23),
    weight: FontWeight.w500,
    height: ar ? 1.55 : 1.28,
  );

  TextStyle body({Color? color, double? size}) => _base(
    size: size ?? (ar ? 15 : 15),
    weight: FontWeight.w300,
    color: color ?? pal.muted,
    height: ar ? 1.95 : 1.75,
  );

  TextStyle kicker([Color? color]) => _base(
    size: ar ? 14 : 11.5,
    weight: ar ? FontWeight.w400 : FontWeight.w500,
    color: color ?? pal.accent,
    height: 1.4,
    spacing: 2.6,
  );

  TextStyle label({Color? color, double? size}) => _base(
    size: size ?? (ar ? 14 : 11.5),
    weight: FontWeight.w500,
    color: color,
    height: 1.4,
    spacing: 2.2,
  );

  TextStyle meta({Color? color}) => _base(
    size: ar ? 13 : 11,
    weight: FontWeight.w400,
    color: color ?? pal.accentSoft,
    height: 1.5,
    spacing: 1.4,
  );

  /// Numerals and wordmarks are always Latin.
  TextStyle latin({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double spacing = 0,
    double? height,
  }) => TextStyle(
    fontFamily: 'NeuePower',
    fontFamilyFallback: const ['Bukra'],
    fontSize: size,
    fontWeight: weight,
    color: color ?? pal.text,
    letterSpacing: spacing,
    height: height,
  );
}

extension TypeContext on BuildContext {
  AppType get type => AppType.of(this);
}

/// Letter-spaced uppercase only makes sense for Latin text.
String tracked(BuildContext context, String text) =>
    Directionality.of(context) == TextDirection.rtl ? text : text.toUpperCase();
