import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/circle_button.dart';

/// "EN" / "AR": switches the app language.
class LangButton extends StatelessWidget {
  const LangButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CircleButton(
    onTap: onTap,
    builder: (context, ink) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Text(
        label,
        key: ValueKey(label),
        style: context.type.latin(
          size: 12,
          weight: FontWeight.w500,
          color: ink,
          spacing: 1.2,
        ),
      ),
    ),
  );
}
