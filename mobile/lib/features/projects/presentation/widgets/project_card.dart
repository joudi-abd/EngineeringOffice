import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/presentation/widgets/project_meta.dart';

/// Image with an inset gold frame that closes in while the tile is pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.builder});
  final VoidCallback onTap;
  final Widget Function(BuildContext context, bool down) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    onTap: () {
      HapticFeedback.selectionClick();
      widget.onTap();
    },
    child: widget.builder(context, _down),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.down});
  final bool down;

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    duration: const Duration(milliseconds: 600),
    curve: Brand.ease,
    top: down ? 18 : 12,
    left: down ? 18 : 12,
    right: down ? 18 : 12,
    bottom: down ? 18 : 12,
    child: IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          border: Border.all(
            color: Brand.goldSoft.withValues(alpha: down ? 0.6 : 0),
          ),
        ),
      ),
    ),
  );
}

/// A project in a list: tall cover, then category, title, summary and place / year.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.heroTag,
    required this.onTap,
  });
  final Project project;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final cover = mediaUrl(project.coverImage);
    return Reveal(
      child: _Pressable(
        onTap: onTap,
        builder: (context, down) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 4.6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: AnimatedScale(
                      scale: down ? 1.035 : 1,
                      duration: const Duration(milliseconds: 900),
                      curve: Brand.ease,
                      child: AppImage(cover),
                    ),
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x00000000),
                            Color(0x66000000),
                          ],
                          stops: [0, 0.6, 1],
                        ),
                      ),
                    ),
                  ),
                  _Frame(down: down),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (project.category != null) ...[
              Kicker(project.category!.name),
              const SizedBox(height: 12),
            ],
            Text(project.title, style: type.title(type.ar ? 25 : 27)),
            if ((project.shortDescription ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                project.shortDescription!,
                style: type.body(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),
            ProjectMeta(project: project),
          ],
        ),
      ),
    );
  }
}

/// A featured project on the home page: full-bleed image with the caption on a dark fade.
class FeaturedShot extends StatelessWidget {
  const FeaturedShot({
    super.key,
    required this.project,
    required this.heroTag,
    required this.onTap,
    this.aspect = 1,
  });

  final Project project;
  final String heroTag;
  final VoidCallback onTap;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final cover = mediaUrl(project.coverImage);
    return Reveal(
      child: _Pressable(
        onTap: onTap,
        builder: (context, down) => AspectRatio(
          aspectRatio: aspect,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: heroTag,
                  child: AnimatedScale(
                    scale: down ? 1.04 : 1,
                    duration: const Duration(milliseconds: 900),
                    curve: Brand.ease,
                    child: AppImage(cover),
                  ),
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x14000000),
                          Color(0x00000000),
                          Color(0x99000000),
                          Color(0xF2000000),
                        ],
                        stops: [0, 0.3, 0.68, 1],
                      ),
                    ),
                  ),
                ),
                _Frame(down: down),
                PositionedDirectional(
                  start: 24,
                  end: 24,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (project.category != null) ...[
                        Kicker(project.category!.name, color: Brand.gold),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        project.title,
                        style: type
                            .title(type.ar ? 25 : 27)
                            .copyWith(color: Brand.paper),
                      ),
                      const SizedBox(height: 10),
                      ProjectMeta(project: project, color: Brand.goldSoft),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
