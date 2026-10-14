import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/features/services/data/service.dart';
import 'package:ufuq_imperium/features/services/presentation/service_icons.dart';
import 'package:ufuq_imperium/features/services/presentation/widgets/service_badge.dart';

/// One numbered service: "01 · icon · name · text".
class ServiceRow extends StatelessWidget {
  const ServiceRow({
    super.key,
    required this.index,
    required this.service,
    this.full = false,
  });
  final int index;
  final Service service;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    final number = index < 10 ? '0$index' : '$index';
    final hasIcon = serviceIconPath(service.icon) != null;
    return Reveal(
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 26, 0, 26),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: pal.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Text(
                number,
                style: type.latin(size: 12, color: pal.accent, spacing: 2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasIcon) ...[
                    ServiceBadge(service.icon),
                    const SizedBox(height: 16),
                  ],
                  Text(service.name, style: type.title(type.ar ? 23 : 24)),
                  if ((service.shortDescription ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(service.shortDescription!, style: type.body()),
                  ],
                  if (full && (service.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(service.description!, style: type.body()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
