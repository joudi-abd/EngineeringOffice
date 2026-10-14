import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/localization/copy.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';

/// A numbered principle: gold rule, outlined numeral, name and text.
class PointRow extends StatelessWidget {
  const PointRow({super.key, required this.point});
  final Point point;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Reveal(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Hairline(),
            const SizedBox(height: 22),
            OutlineNumber(point.index),
            const SizedBox(height: 18),
            Text(point.name, style: type.title()),
            const SizedBox(height: 8),
            Text(point.text, style: type.body()),
          ],
        ),
      ),
    );
  }
}
