import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/features/team/data/team_member.dart';

/// A team member: portrait (or initial) with name, role and short bio.
class MemberCard extends StatelessWidget {
  const MemberCard({super.key, required this.member, this.width});
  final TeamMember member;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    final photo = mediaUrl(member.imageUrl ?? member.image);
    final initial = member.name.trim().isEmpty
        ? ''
        : String.fromCharCode(member.name.trim().runes.first);
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: pal.line),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.cardTop, pal.cardBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: photo.isNotEmpty
                ? AppImage(photo, cacheWidth: 700)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.24),
                        radius: 0.58,
                        colors: [
                          pal.glow.withValues(alpha: pal.dark ? 0.28 : 0.3),
                          pal.dark ? Colors.black : pal.bg3,
                        ],
                        stops: const [0, 1],
                      ),
                      color: pal.dark ? Colors.black : pal.bg3,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: type.latin(
                          size: 64,
                          weight: FontWeight.w500,
                          color: pal.accent,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: type.title(22)),
                const SizedBox(height: 6),
                Text(
                  member.jobTitle,
                  style: type
                      .body(color: pal.accent, size: 14)
                      .copyWith(fontWeight: FontWeight.w400),
                ),
                if ((member.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: pal.line),
                  const SizedBox(height: 14),
                  Text(
                    member.bio!,
                    style: type.body(size: 14),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
