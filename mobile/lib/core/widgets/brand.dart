import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';

/// A one-pixel rule that fades out, the way every section on the website is underlined.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color, this.fade = true});
  final Color? color;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.pal.accent;
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: fade
            ? LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0),
                ],
              )
            : null,
        color: fade ? null : color,
      ),
    );
  }
}

/// Section label: "01 ── ABOUT THE OFFICE".
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.index, this.color});
  final String text;
  final String? index;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    final color = this.color ?? pal.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (index != null) ...[
          Text(
            index!,
            style: type.latin(size: 12, color: pal.accentSoft, spacing: 2.4),
          ),
          const SizedBox(width: 12),
        ],
        Container(width: 30, height: 1, color: color),
        const SizedBox(width: 12),
        Flexible(
          child: Text(tracked(context, text), style: type.kicker(color)),
        ),
      ],
    );
  }
}

/// Large heading used by every section.
class Display extends StatelessWidget {
  const Display(this.text, {super.key, this.size, this.color});
  final String text;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.type.display(size).copyWith(color: color));
}

/// "MORE ABOUT THE OFFICE  →" with a gold underline that stretches while pressed.
class GoldLink extends StatefulWidget {
  const GoldLink(
    this.label, {
    super.key,
    required this.onTap,
    this.arrow = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool arrow;

  @override
  State<GoldLink> createState() => _GoldLinkState();
}

class _GoldLinkState extends State<GoldLink> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      tracked(context, widget.label),
                      style: type.label(
                        color: _down ? pal.accentSoft : pal.text,
                        size: type.ar ? 15 : 11,
                      ),
                    ),
                  ),
                  if (widget.arrow) ...[
                    const SizedBox(width: 12),
                    Transform.flip(
                      flipX: rtl,
                      child: PathIcon(
                        Glyphs.arrow,
                        size: 18,
                        color: pal.accent,
                        strokeWidth: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Brand.ease,
                  height: 1,
                  width: _down ? 220 : 40,
                  color: pal.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined gold button that floods with gold while pressed.
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool expand;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    final disabled = widget.onTap == null || widget.busy;
    final fill = _down && !disabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Brand.ease,
        height: 56,
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill ? pal.accentSoft : Colors.transparent,
          border: Border.all(color: disabled ? pal.goldLine : pal.accent),
          boxShadow: fill
              ? [
                  BoxShadow(
                    color: pal.accent.withValues(alpha: 0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ]
              : const [],
        ),
        child: widget.busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.2,
                  color: pal.accentSoft,
                ),
              )
            : Text(
                tracked(context, widget.label),
                style: type
                    .label(
                      color: fill
                          ? pal.onAccent
                          : (disabled ? pal.faint : pal.accentSoft),
                      size: type.ar ? 17 : 12,
                    )
                    .copyWith(letterSpacing: type.ar ? 0 : 2.8),
              ),
      ),
    );
  }
}

/// Big numerals drawn as an outline only, like the numbered principles on the website.
class OutlineNumber extends StatelessWidget {
  const OutlineNumber(this.text, {super.key, this.size = 54});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: TextDirection.ltr,
    style: TextStyle(
      fontFamily: 'NeuePower',
      fontSize: size,
      fontWeight: FontWeight.w300,
      height: 1,
      letterSpacing: 1,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = context.pal.accent.withValues(alpha: 0.85),
    ),
  );
}

/// A remote image that fades in over a dark placeholder and falls back to the brand mark.
class AppImage extends StatelessWidget {
  const AppImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth = 900,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;

  /// Decoded width in physical pixels; keeps memory down for long lists.
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _Backdrop();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: alignment,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 700),
      fadeInCurve: Brand.ease,
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => const _Backdrop(),
      errorWidget: (_, _, _) => const _Backdrop(mark: true),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({this.mark = true});
  final bool mark;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.9,
        colors: context.pal.dark
            ? const [Color(0xFF1A1613), Color(0xFF0B0A09)]
            : const [Color(0xFFE6E0D3), Color(0xFFD3CBBA)],
      ),
    ),
    child: mark
        ? Center(
            child: Opacity(
              opacity: 0.16,
              child: Image.asset('assets/brand/mark-gold.png', width: 72),
            ),
          )
        : null,
  );
}

/// Five stars, filled up to [value]. Pass [onChanged] to make it an input.
class Stars extends StatelessWidget {
  const Stars({
    super.key,
    required this.value,
    this.size = 16,
    this.onChanged,
    this.gap = 4,
  });
  final int value;
  final double size;
  final double gap;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final input = onChanged != null;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (var star = 1; star <= 5; star++)
          Semantics(
            button: input,
            excludeSemantics: true,
            selected: input ? star <= value : null,
            label: input ? '$star' : null,
            onTap: input ? () => onChanged!(star) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged!(star);
                    },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: onChanged == null ? gap / 2 : gap + 2,
                  vertical: onChanged == null ? 0 : 8,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: PathIcon(
                    Glyphs.star,
                    key: ValueKey('$star-${star <= value}'),
                    size: size,
                    viewBox: 20,
                    filled: star <= value,
                    color: star <= value
                        ? pal.accentSoft
                        : pal.accent.withValues(alpha: 0.55),
                    strokeWidth: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return input
        ? row
        : Semantics(label: '$value / 5', excludeSemantics: true, child: row);
  }
}
