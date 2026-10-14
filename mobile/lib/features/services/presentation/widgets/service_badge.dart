import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';
import 'package:ufuq_imperium/features/services/presentation/service_icons.dart';

/// Gold-ringed circle holding a service's icon.
class ServiceBadge extends StatelessWidget {
  const ServiceBadge(this.icon, {super.key, this.size = 46});
  final String? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final path = serviceIconPath(icon);
    if (path == null) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: pal.accentSoft.withValues(alpha: 0.4)),
      ),
      child: PathIcon(path, size: size * 0.46, strokeWidth: 1.4),
    );
  }
}
