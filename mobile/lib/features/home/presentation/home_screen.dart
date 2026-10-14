import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/point_row.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/core/widgets/states.dart';
import 'package:ufuq_imperium/features/projects/presentation/open_project.dart';
import 'package:ufuq_imperium/features/projects/presentation/widgets/project_card.dart';
import 'package:ufuq_imperium/features/projects/state/projects_controller.dart';
import 'package:ufuq_imperium/features/services/presentation/widgets/service_marquee.dart';
import 'package:ufuq_imperium/features/services/presentation/widgets/service_row.dart';
import 'package:ufuq_imperium/features/services/state/services_controller.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';
import 'package:ufuq_imperium/features/shell/presentation/shell_scope.dart';
import 'package:ufuq_imperium/features/shell/presentation/tab_page.dart';
import 'package:ufuq_imperium/features/team/presentation/widgets/member_card.dart';
import 'package:ufuq_imperium/features/team/state/team_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final servicesCtl = context.watch<ServicesController>();
    final teamCtl = context.watch<TeamController>();
    final projectsCtl = context.watch<ProjectsController>();
    final c = locale.c;
    final type = context.type;
    final pal = context.pal;
    final shell = ShellScope.of(context);
    var chapter = 0;
    String nextIndex() => '0${++chapter}';

    final services = servicesCtl.services;
    final team = teamCtl.team;
    final featured = projectsCtl.featured;

    return TabPage(
      slivers: [
        SliverToBoxAdapter(child: const _Hero()),

        // ------------------------------------------------------------ about
        SliverToBoxAdapter(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: AlignmentDirectional(-1, 0),
                      radius: 1.0,
                      colors: [Color(0x21AA8E69), Color(0x00AA8E69)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        end: -50,
                        top: 70,
                        width: 300,
                        child: Opacity(
                          opacity: 0.08,
                          child: Image.asset('assets/brand/mark-gold.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(kGutter, 78, kGutter, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(child: Kicker(c.aboutEyebrow, index: nextIndex())),
                    const SizedBox(height: 26),
                    Reveal(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        c.aboutTitle,
                        style: type.headline(type.ar ? 33 : 40),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Reveal(
                      delay: const Duration(milliseconds: 160),
                      child: Text(
                        c.aboutLede,
                        style: type.body(size: type.ar ? 16 : 16),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Reveal(
                      delay: const Duration(milliseconds: 220),
                      child: GoldLink(c.aboutMore, onTap: () => shell.goTo(1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ------------------------------------------------------------ team
        // if (team.isNotEmpty)
        //   SliverToBoxAdapter(
        //     child: Padding(
        //       padding: const EdgeInsets.only(bottom: 84),
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Padding(
        //             padding: const EdgeInsets.symmetric(horizontal: kGutter),
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Reveal(
        //                   child: Kicker(c.teamEyebrow, index: nextIndex()),
        //                 ),
        //                 const SizedBox(height: 24),
        //                 Reveal(
        //                   delay: const Duration(milliseconds: 80),
        //                   child: Display(c.teamTitle),
        //                 ),
        //               ],
        //             ),
        //           ),
        //           const SizedBox(height: 34),
        //           Reveal(
        //             delay: const Duration(milliseconds: 140),
        //             // Sized by the tallest card, so long names or large system text never overflow.
        //             child: SingleChildScrollView(
        //               scrollDirection: Axis.horizontal,
        //               padding: const EdgeInsets.symmetric(horizontal: kGutter),
        //               physics: const BouncingScrollPhysics(),
        //               child: IntrinsicHeight(
        //                 child: Row(
        //                   crossAxisAlignment: CrossAxisAlignment.stretch,
        //                   children: [
        //                     for (var i = 0; i < team.length; i++) ...[
        //                       if (i > 0) const SizedBox(width: 16),
        //                       MemberCard(member: team[i], width: 252),
        //                     ],
        //                   ],
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),

        // ------------------------------------------------------------ services
        // SliverToBoxAdapter(
        //   child: Container(
        //     decoration: BoxDecoration(
        //       color: pal.bg2,
        //       gradient: RadialGradient(
        //         center: const AlignmentDirectional(1, -1),
        //         radius: 1.0,
        //         colors: [
        //           pal.glow.withValues(alpha: 0.1),
        //           pal.glow.withValues(alpha: 0),
        //         ],
        //       ),
        //     ),
        //     padding: const EdgeInsets.fromLTRB(kGutter, 80, kGutter, 70),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Reveal(child: Kicker(c.servicesEyebrow, index: nextIndex())),
        //         const SizedBox(height: 24),
        //         Reveal(
        //           delay: const Duration(milliseconds: 80),
        //           child: Display(c.servicesTitle),
        //         ),
        //         const SizedBox(height: 20),
        //         Reveal(
        //           delay: const Duration(milliseconds: 140),
        //           child: Text(c.servicesLede, style: type.body()),
        //         ),
        //         const SizedBox(height: 10),
        //         Reveal(
        //           delay: const Duration(milliseconds: 190),
        //           child: GoldLink(c.servicesMore, onTap: () => shell.goTo(2)),
        //         ),
        //         const SizedBox(height: 34),
        //         if (services.isEmpty)
        //           EmptyNote(c.servicesEmpty)
        //         else
        //           for (var i = 0; i < services.length; i++)
        //             ServiceRow(index: i + 1, service: services[i]),
        //         if (services.isNotEmpty) Container(height: 1, color: pal.line),
        //       ],
        //     ),
        //   ),
        // ),

        // ------------------------------------------------------------ featured projects
        // SliverToBoxAdapter(
        //   child: Padding(
        //     padding: const EdgeInsets.fromLTRB(0, 84, 0, 86),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Padding(
        //           padding: const EdgeInsets.symmetric(horizontal: kGutter),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Reveal(
        //                 child: Kicker(c.projectsEyebrow, index: nextIndex()),
        //               ),
        //               const SizedBox(height: 24),
        //               Reveal(
        //                 delay: const Duration(milliseconds: 80),
        //                 child: Display(c.projectsTitle),
        //               ),
        //               const SizedBox(height: 20),
        //               Reveal(
        //                 delay: const Duration(milliseconds: 140),
        //                 child: Text(c.projectsLede, style: type.body()),
        //               ),
        //               const SizedBox(height: 10),
        //               Reveal(
        //                 delay: const Duration(milliseconds: 190),
        //                 child: GoldLink(
        //                   c.projectsMore,
        //                   onTap: () => shell.goTo(3),
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //         const SizedBox(height: 34),
        //         if (featured.isEmpty)
        //           Padding(
        //             padding: const EdgeInsets.symmetric(horizontal: kGutter),
        //             child: EmptyNote(c.projectsEmpty),
        //           )
        //         else
        //           for (var i = 0; i < featured.length; i++)
        //             Padding(
        //               padding: EdgeInsets.only(
        //                 bottom: i == featured.length - 1 ? 0 : 14,
        //               ),
        //               child: FeaturedShot(
        //                 project: featured[i],
        //                 heroTag: 'home-cover-${featured[i].id}',
        //                 aspect: i == 0 ? 0.84 : 1.05,
        //                 onTap: () => openProject(
        //                   context,
        //                   featured[i],
        //                   'home-cover-${featured[i].id}',
        //                 ),
        //               ),
        //             ),
        //       ],
        //     ),
        //   ),
        // ),

        // ------------------------------------------------------------ why
        // SliverToBoxAdapter(
        //   child: Container(
        //     color: pal.bg2,
        //     padding: const EdgeInsets.fromLTRB(kGutter, 80, kGutter, 80),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Reveal(child: Kicker(c.whyEyebrow, index: nextIndex())),
        //         const SizedBox(height: 24),
        //         Reveal(
        //           delay: const Duration(milliseconds: 80),
        //           child: Display(c.whyTitle),
        //         ),
        //         const SizedBox(height: 40),
        //         for (final point in c.why) PointRow(point: point),
        //       ],
        //     ),
        //   ),
        // ),

        // ------------------------------------------------------------ contact
        SliverToBoxAdapter(child: _ContactCall(index: nextIndex())),
      ],
    );
  }
}

class _ContactCall extends StatelessWidget {
  const _ContactCall({required this.index});
  final String index;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final settings = context.watch<SettingsController>();
    final c = locale.c;
    final type = context.type;
    final pal = context.pal;
    final shell = ShellScope.of(context);
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
            padding: const EdgeInsets.fromLTRB(kGutter, 70, kGutter, 78),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(child: Kicker(c.contactEyebrow, index: index)),
                const SizedBox(height: 24),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Display(c.contactTitle),
                ),
                if (settings.phone.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Reveal(
                    delay: const Duration(milliseconds: 140),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => openExternal(telUri(settings.phone)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          settings.phone,
                          textDirection: TextDirection.ltr,
                          style: type.latin(
                            size: 31,
                            color: pal.accentSoft,
                            spacing: 1,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 200),
                  child: GoldLink(c.contactEyebrow, onTap: () => shell.goTo(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------- hero

class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _span(double a, double b, [Curve curve = Brand.ease]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(a, b, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final locale = context.watch<LocaleController>();
    final pal = context.pal;
    final height = math.max(560.0, size.height - kNavHeight - bottom);
    final drawingHeight = height * 0.86;
    final scroll = ShellScope.of(context).homeScroll;
    final wordSize = ((size.width - 60) / 7.2).clamp(36.0, 62.0);

    final drawing = _span(0, 0.6, Curves.easeOutCubic);
    final riseA = _span(0.18, 0.62);
    final riseB = _span(0.25, 0.7);
    final script = _span(0.55, 0.95, Curves.easeOut);
    final frame = _span(0.3, 0.72, Curves.easeOut);

    Widget rise(Animation<double> a, Widget child) => AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, child) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - a.value) * 34),
          child: child,
        ),
      ),
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // architectural elevation (SVG), with a slow settle and a gentle parallax
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: drawingHeight,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: Listenable.merge([drawing, scroll]),
                builder: (_, _) {
                  final offset = scroll.hasClients
                      ? scroll.offset.clamp(0.0, 900.0)
                      : 0.0;
                  return Opacity(
                    opacity: drawing.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, offset * 0.12),
                      child: Transform.scale(
                        scale: 1.1 - 0.1 * drawing.value,
                        alignment: const Alignment(0, 0.35),
                        child: SvgPicture.asset(
                          pal.dark
                              ? 'assets/images/hero.svg'
                              : 'assets/images/hero-day.svg',
                          fit: BoxFit.cover,
                          // On wider screens (tablets, split view) the drawing is cropped by its
                          // width, so centre on the building instead of the sky.
                          alignment: size.width / drawingHeight > 390 / 700
                              ? const Alignment(0, 0.1)
                              : Alignment.topCenter,
                          semanticsLabel: locale.isArabic
                              ? 'مخطط معماري لمبنى بخطوط ذهبية تحت شمس مشرقة'
                              : 'An architectural elevation drawn in gold lines, with the sun rising through the gate',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // shade: keeps the top bar legible and melts the bottom into black
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: drawingHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      pal.bg.withValues(alpha: 0.7),
                      pal.bg.withValues(alpha: 0),
                      pal.bg.withValues(alpha: 0),
                      pal.bg.withValues(alpha: 0.6),
                      pal.bg,
                    ],
                    stops: const [0, 0.14, 0.62, 0.86, 1],
                  ),
                ),
              ),
            ),
          ),

          // thin gold frame with two corner ticks
          Positioned(
            top: top + kBarHeight + 6,
            left: 14,
            right: 14,
            height: drawingHeight - (top + kBarHeight + 6) + 8,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: frame,
                child: CustomPaint(painter: _FramePainter(pal)),
              ),
            ),
          ),

          // wordmark
          Positioned(
            left: 28,
            bottom: height * 0.05 + 20,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The wordmark is a logo, not reading text: it keeps its size when the phone's font scale is raised.
                  rise(
                    riseA,
                    Text(
                      'UFUQ',
                      style: _wordStyle(wordSize, pal),
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                  rise(
                    riseB,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'IMPERIUM',
                          style: _wordStyle(wordSize, pal),
                          textScaler: TextScaler.noScaling,
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: EdgeInsets.only(top: wordSize * 0.46),
                          child: FadeTransition(
                            opacity: script,
                            child: Text(
                              'Urbanism',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontFamily: 'NeuePower',
                                fontSize: wordSize * 0.28,
                                color: pal.accent,
                                letterSpacing: 0.8,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _wordStyle(double size, Palette pal) => TextStyle(
    fontFamily: 'NeuePower',
    fontSize: size,
    fontWeight: FontWeight.w500,
    height: 0.96,
    letterSpacing: size * 0.04,
    color: pal.text,
    shadows: pal.dark
        ? const [
            Shadow(
              color: Color(0x2E000000),
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
          ]
        : null,
  );
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.pal);
  final Palette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = pal.accentSoft.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(path, line);

    final tick = Paint()
      ..color = pal.accentSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const len = 22.0;
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      tick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      tick,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.pal != pal;
}
