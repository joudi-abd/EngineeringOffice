import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';

/// Underlined text field: small label above, line that turns gold on focus.
class LuxField extends StatefulWidget {
  const LuxField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.ltr = false,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool ltr;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final VoidCallback? onChanged;

  @override
  State<LuxField> createState() => _LuxFieldState();
}

class _LuxFieldState extends State<LuxField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    final focused = _focus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 260),
          style: type
              .body(
                color: focused ? pal.accentSoft : pal.muted,
                size: type.ar ? 14.5 : 13,
              )
              .copyWith(fontWeight: FontWeight.w400),
          child: Text(widget.label),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          minLines: widget.maxLines > 1 ? 3 : 1,
          maxLines: widget.maxLines,
          textDirection: widget.ltr ? TextDirection.ltr : null,
          textAlign: widget.ltr ? TextAlign.left : TextAlign.start,
          textInputAction:
              widget.textInputAction ??
              (widget.maxLines > 1
                  ? TextInputAction.newline
                  : TextInputAction.next),
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged == null
              ? null
              : (_) => widget.onChanged!(),
          cursorColor: pal.accentSoft,
          cursorWidth: 1.4,
          style: type
              .body(color: pal.text, size: 17)
              .copyWith(
                fontWeight: FontWeight.w400,
                height: type.ar ? 1.7 : 1.5,
              ),
          decoration: const InputDecoration(
            isDense: true,
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Brand.ease,
          height: focused ? 1.6 : 1,
          color: focused ? pal.accent : pal.line,
        ),
      ],
    );
  }
}

/// Square gold checkbox with a label.
class LuxCheck extends StatelessWidget {
  const LuxCheck({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Brand.ease,
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: value ? pal.accentSoft : Colors.transparent,
                border: Border.all(color: value ? pal.accentSoft : pal.accent),
              ),
              child: value
                  ? Center(
                      child: PathIcon(
                        Glyphs.check,
                        size: 15,
                        color: pal.onAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: type.body(size: 14.5))),
          ],
        ),
      ),
    );
  }
}
