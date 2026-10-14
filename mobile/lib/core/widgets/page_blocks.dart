import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';

/// Header of an inner page: kicker, headline and lede over a warm glow and the brand mark.
class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.kicker,
    required this.title,
    this.lede,
    this.index,
  });
  final String kicker;
  final String title;
  final String? lede;
  final String? index;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: AlignmentDirectional(-0.9, -1),
          radius: 1.1,
          colors: [Color(0x2BAA8E69), Color(0x00AA8E69)],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -34,
            top: top + kBarHeight + 24,
            width: 250,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/brand/mark-gold.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              kGutter,
              top + kBarHeight + 34,
              kGutter,
              46,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(child: Kicker(kicker, index: index)),
                const SizedBox(height: 22),
                Reveal(
                  delay: const Duration(milliseconds: 90),
                  child: Text(title, style: type.headline()),
                ),
                if (lede != null && lede!.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Reveal(
                    delay: const Duration(milliseconds: 180),
                    child: Text(lede!, style: type.body()),
                  ),
                ],
                const SizedBox(height: 40),
                const Reveal(
                  delay: Duration(milliseconds: 260),
                  child: Hairline(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Closing block of a page: a heading and one or two gold links.
class PageNext extends StatelessWidget {
  const PageNext({super.key, required this.title, required this.links});
  final String title;
  final List<({String label, VoidCallback onTap})> links;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.bg3, pal.bg],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: AlignmentDirectional(-1, 1),
                  radius: 1.0,
                  colors: [Color(0x29AA8E69), Color(0x00AA8E69)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 64, kGutter, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Reveal(child: Hairline()),
                const SizedBox(height: 34),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Display(title),
                ),
                const SizedBox(height: 22),
                Reveal(
                  delay: const Duration(milliseconds: 160),
                  child: Wrap(
                    spacing: 34,
                    runSpacing: 6,
                    children: [
                      for (final link in links)
                        GoldLink(link.label, onTap: link.onTap),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
