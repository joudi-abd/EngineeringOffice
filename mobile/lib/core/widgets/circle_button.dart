import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';

/// The round outlined button used in the top bars: gold ring, floods with gold while pressed.
/// [builder] draws the content in the colour it should have for the current state.
class CircleButton extends StatefulWidget {
  const CircleButton({
    super.key,
    required this.onTap,
    required this.builder,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget Function(BuildContext context, Color ink) builder;
  final String? semanticLabel;

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final ink = _down ? pal.onAccent : pal.accentSoft;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Brand.ease,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _down ? pal.accentSoft : Colors.transparent,
              border: Border.all(
                color: _down
                    ? pal.accentSoft
                    : pal.accentSoft.withValues(alpha: 0.5),
              ),
            ),
            child: widget.builder(context, ink),
          ),
        ),
      ),
    );
  }
}
