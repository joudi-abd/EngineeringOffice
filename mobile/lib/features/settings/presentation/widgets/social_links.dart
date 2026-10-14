import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';

/// Round gold-bordered links to the office's accounts.
class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key, this.labelled = false});
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final items = settings.social;
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          _SocialButton(
            glyph: item.key == 'facebook' ? Glyphs.facebook : Glyphs.instagram,
            label: labelled ? item.label : null,
            semantics: item.label,
            onTap: () => openExternal(Uri.parse(item.href)),
          ),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.glyph,
    required this.semantics,
    required this.onTap,
    this.label,
  });
  final String glyph;
  final String semantics;
  final String? label;
  final VoidCallback onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    final color = _down ? pal.onAccent : pal.accentSoft;
    return Semantics(
      button: true,
      label: widget.semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Brand.ease,
          height: 48,
          width: widget.label == null ? 48 : null,
          padding: widget.label == null
              ? EdgeInsets.zero
              : const EdgeInsetsDirectional.only(start: 18, end: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: _down ? pal.goldGradient : null,
            border: Border.all(
              color: _down
                  ? Colors.transparent
                  : pal.accentSoft.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PathIcon(widget.glyph, size: 20, color: color, strokeWidth: 1.5),
              if (widget.label != null) ...[
                const SizedBox(width: 11),
                Text(
                  widget.label!.toUpperCase(),
                  style: type.latin(size: 12, color: color, spacing: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
