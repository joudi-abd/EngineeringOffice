import 'package:flutter/material.dart';

/// Brand tokens, taken from the public website so both feel like the same house.
class Brand {
  static const ink = Color(0xFF000000);
  static const ink2 = Color(0xFF141414);
  static const ink3 = Color(0xFF0A0908);
  static const paper = Color(0xFFF2F0EB);
  static const gold = Color(0xFFAA8E69);
  static const goldDeep = Color(0xFF7D5D3B);
  static const goldSoft = Color(0xFFCBB892);

  static const muted = Color(0xB8F2F0EB); // paper @ 72%
  static const faint = Color(0x66F2F0EB); // paper @ 40%
  static const line = Color(0x29F2F0EB); // paper @ 16%
  static const lineSoft = Color(0x14F2F0EB); // paper @ 8%
  static const goldLine = Color(0x38CBB892); // gold-soft @ 22%
  static const error = Color(0xFFE7B4A4);

  static const goldGradient = LinearGradient(
    begin: Alignment(-1, -0.35),
    end: Alignment(1, 0.35),
    colors: [goldSoft, gold, goldDeep],
    stops: [0, 0.48, 1],
  );

  /// Same curve as the website (`cubic-bezier(.22,.61,.36,1)`).
  static const ease = Cubic(0.22, 0.61, 0.36, 1);
  static const easeInOut = Cubic(0.77, 0, 0.18, 1);
}

/// The colours that change between the night (black) and day (beige) looks.
///
/// Read it with `context.pal`. The constants on [Brand] are the fixed brand colours; use those only
/// for surfaces that are always dark, such as text laid over photographs or the gallery viewer.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.dark,
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.text,
    required this.muted,
    required this.faint,
    required this.line,
    required this.lineSoft,
    required this.accent,
    required this.accentSoft,
    required this.goldLine,
    required this.error,
    required this.onAccent,
    required this.bar,
    required this.cardTop,
    required this.cardBottom,
    required this.glow,
    required this.goldGradient,
  });

  final bool dark;

  /// Page background, then two alternating section backgrounds.
  final Color bg;
  final Color bg2;
  final Color bg3;

  /// Headlines, body text (muted), small print (faint) and hairlines.
  final Color text;
  final Color muted;
  final Color faint;
  final Color line;
  final Color lineSoft;

  /// The gold accent: strong (rules, borders, kickers) and soft (links, labels, icons).
  final Color accent;
  final Color accentSoft;
  final Color goldLine;
  final Color error;

  /// Text or icon colour on a gold fill.
  final Color onAccent;

  /// Frosted bar behind the bottom navigation.
  final Color bar;
  final Color cardTop;
  final Color cardBottom;

  /// Colour of the soft glows behind sections.
  final Color glow;
  final LinearGradient goldGradient;

  static const night = Palette(
    dark: true,
    bg: Brand.ink,
    bg2: Brand.ink2,
    bg3: Brand.ink3,
    text: Brand.paper,
    muted: Brand.muted,
    faint: Brand.faint,
    line: Brand.line,
    lineSoft: Brand.lineSoft,
    accent: Brand.gold,
    accentSoft: Brand.goldSoft,
    goldLine: Brand.goldLine,
    error: Brand.error,
    onAccent: Color(0xFF000000),
    bar: Color(0xE6050403),
    cardTop: Color(0x09FFFFFF),
    cardBottom: Color(0x00FFFFFF),
    glow: Brand.gold,
    goldGradient: Brand.goldGradient,
  );

  /// Day look: the brand's beige "Magical Moonlight" with black type and the deeper gold.
  static const day = Palette(
    dark: false,
    bg: Color(0xFFF2F0EB),
    bg2: Color(0xFFE8E4DA),
    bg3: Color(0xFFDDD7C9),
    text: Color(0xFF000000),
    muted: Color(0xFF666666),
    faint: Color(0xFF8A8780),
    line: Color(0x29000000),
    lineSoft: Color(0x14000000),
    accent: Color(0xFF8D704E),
    accentSoft: Color(0xFF7A5E3E),
    goldLine: Color(0x388D704E),
    error: Color(0xFFA8392A),
    onAccent: Color(0xFFF2F0EB),
    bar: Color(0xEBF2F0EB),
    cardTop: Color(0x99FFFFFF),
    cardBottom: Color(0x33FFFFFF),
    glow: Color(0xFFAA8E69),
    goldGradient: LinearGradient(
      begin: Alignment(-1, -0.35),
      end: Alignment(1, 0.35),
      colors: [Color(0xFFA78A62), Color(0xFF8D704E), Color(0xFF6B4D2E)],
      stops: [0, 0.48, 1],
    ),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      dark: t < 0.5 ? dark : other.dark,
      bg: c(bg, other.bg),
      bg2: c(bg2, other.bg2),
      bg3: c(bg3, other.bg3),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      line: c(line, other.line),
      lineSoft: c(lineSoft, other.lineSoft),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      goldLine: c(goldLine, other.goldLine),
      error: c(error, other.error),
      onAccent: c(onAccent, other.onAccent),
      bar: c(bar, other.bar),
      cardTop: c(cardTop, other.cardTop),
      cardBottom: c(cardBottom, other.cardBottom),
      glow: c(glow, other.glow),
      goldGradient: LinearGradient.lerp(goldGradient, other.goldGradient, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>() ?? Palette.night;
}

/// Horizontal page padding.
const double kGutter = 26;

/// Height of the top bar (below the status bar) and of the bottom navigation.
const double kBarHeight = 64;
const double kNavHeight = 66;
