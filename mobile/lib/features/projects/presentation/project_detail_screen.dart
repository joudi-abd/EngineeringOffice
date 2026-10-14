import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/theme_button.dart';
import 'package:ufuq_imperium/core/widgets/lux_route.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/data/projects_repository.dart';
import 'package:ufuq_imperium/features/projects/data/review.dart';
import 'package:ufuq_imperium/features/projects/presentation/gallery_viewer.dart';
import 'package:ufuq_imperium/features/projects/presentation/widgets/review_sheet.dart';
import 'package:ufuq_imperium/features/projects/presentation/widgets/video_tile.dart';
import 'package:ufuq_imperium/features/projects/state/projects_controller.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.summary,
    required this.heroTag,
  });
  final Project summary;
  final String heroTag;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

enum _Status { loading, ready, missing }

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _solid = ValueNotifier(false);
  Project? _raw;
  List<Review> _reviews = const [];
  _Status _status = _Status.loading;
  int _rating = 0;
  bool _thanks = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(
      () => _solid.value = _scroll.hasClients && _scroll.offset > 24,
    );
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<ProjectsRepository>();
    try {
      final project = await repository.bySlug(widget.summary.slug);
      if (!mounted) return;
      if (project == null) {
        setState(() => _status = _Status.missing);
        return;
      }
      setState(() {
        _raw = project;
        _status = _Status.ready;
      });
      _loadReviews(project.id);
    } catch (_) {
      // Offline: keep showing what the list already knew.
      if (mounted) setState(() => _status = _Status.ready);
      _loadReviews(widget.summary.id);
    }
  }

  Future<void> _loadReviews(int id) async {
    final items = await context.read<ProjectsRepository>().reviews(id);
    if (mounted) setState(() => _reviews = items);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _solid.dispose();
    super.dispose();
  }

  Future<void> _rate(int stars) async {
    setState(() => _rating = stars);
    final sent = await ReviewSheet.show(
      context,
      projectId: widget.summary.id,
      rating: stars,
    );
    if (!mounted) return;
    if (sent == true) {
      setState(() {
        _thanks = true;
        _rating = 0;
      });
      _loadReviews(widget.summary.id);
    } else {
      setState(() => _rating = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = context.watch<LocaleController>();
    final projectsCtl = context.watch<ProjectsController>();
    final c = locale.c;
    final type = context.type;
    final raw = _raw;
    final project = raw != null ? projectsCtl.localize(raw) : widget.summary;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final shots = _shots(project);
    final videos = _videos(project);
    final body = paragraphs(project.description);

    return Scaffold(
      backgroundColor: pal.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: top + kBarHeight + 6),

                if (_status == _Status.missing)
                  _Missing(title: c.missingTitle, text: c.missing)
                else ...[
                  // gallery
                  if (shots.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _Mosaic(
                        shots: shots,
                        heroTag: widget.heroTag,
                        label: c.galleryEyebrow,
                        onOpen: (i) => _openViewer(shots, i),
                      ),
                    ),

                  // heading
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kGutter, 36, kGutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project.category != null) ...[
                          Reveal(child: Kicker(project.category!.name)),
                          const SizedBox(height: 20),
                        ],
                        Reveal(
                          delay: const Duration(milliseconds: 70),
                          child: Text(
                            project.title,
                            style: type.headline(type.ar ? 31 : 38),
                          ),
                        ),
                        if ((project.shortDescription ?? '').isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Reveal(
                            delay: const Duration(milliseconds: 140),
                            child: Text(
                              project.shortDescription!,
                              style: type.body(size: 16),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Reveal(
                          delay: const Duration(milliseconds: 200),
                          child: _Facts(project: project),
                        ),
                      ],
                    ),
                  ),

                  // description
                  if (body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kGutter,
                        38,
                        kGutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final paragraph in body)
                            Reveal(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Text(
                                  paragraph,
                                  style: type.body(size: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // videos
                  if (videos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kGutter,
                        56,
                        kGutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Reveal(child: Kicker(c.videosEyebrow)),
                          const SizedBox(height: 20),
                          Reveal(
                            delay: const Duration(milliseconds: 70),
                            child: Display(c.videosTitle),
                          ),
                          const SizedBox(height: 26),
                          for (final video in videos)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Reveal(
                                child: video.file
                                    ? FileVideoTile(
                                        url: video.src,
                                        title: video.title,
                                      )
                                    : LinkVideoTile(
                                        link: video.src,
                                        title: video.title,
                                        label: c.openVideo,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // services
                  if (project.services.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kGutter,
                        56,
                        kGutter,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Reveal(child: Kicker(c.projectServicesEyebrow)),
                          const SizedBox(height: 20),
                          Reveal(
                            delay: const Duration(milliseconds: 70),
                            child: Display(c.projectServicesTitle),
                          ),
                          const SizedBox(height: 24),
                          Reveal(
                            delay: const Duration(milliseconds: 120),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final s in project.services) _Pill(s.name),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // reviews
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kGutter, 64, kGutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Reveal(child: Kicker(c.reviewsEyebrow)),
                        const SizedBox(height: 20),
                        Reveal(
                          delay: const Duration(milliseconds: 70),
                          child: Display(c.reviewsTitle),
                        ),
                        const SizedBox(height: 26),
                        if (_reviews.isEmpty)
                          Text(c.reviewsEmpty, style: type.body())
                        else
                          for (final review in _reviews)
                            _Comment(
                              review: projectsCtl.localizeReview(review),
                            ),
                        const SizedBox(height: 30),
                        Text(c.rateLabel, style: type.body(size: 14)),
                        const SizedBox(height: 6),
                        Semantics(
                          label: c.rateLabel,
                          child: Stars(
                            value: _rating,
                            size: 32,
                            gap: 6,
                            onChanged: _rate,
                          ),
                        ),
                        if (_thanks)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Row(
                              children: [
                                const PathIcon(
                                  Glyphs.check,
                                  size: 18,
                                  strokeWidth: 1.8,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.thanks,
                                    style: type
                                        .body(color: pal.accentSoft, size: 15)
                                        .copyWith(fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 90 + bottom),
              ],
            ),
          ),

          // top bar: back + language
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _solid,
              builder: (_, solid, _) => _DetailBar(
                solid: solid,
                backLabel: c.back,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(List<GalleryShot> shots, int index) {
    final c = context.read<LocaleController>().c;
    Navigator.of(context).push(
      LuxRoute<void>(
        fade: true,
        builder: (_) =>
            GalleryViewer(shots: shots, initial: index, closeLabel: c.close),
      ),
    );
  }

  List<GalleryShot> _shots(Project project) {
    final images = [...project.images]..sort((a, b) => a.id.compareTo(b.id));
    if (images.isNotEmpty) {
      return [
        for (final image in images)
          GalleryShot(
            src: mediaUrl(image.url ?? image.path),
            alt: image.alt ?? project.title,
          ),
      ].where((s) => s.src.isNotEmpty).toList();
    }
    final cover = mediaUrl(project.coverImage);
    return cover.isEmpty
        ? const []
        : [GalleryShot(src: cover, alt: project.title)];
  }

  List<_Video> _videos(Project project) {
    final items = [...project.videos]..sort((a, b) => a.id.compareTo(b.id));
    final out = <_Video>[];
    for (final video in items) {
      final title = video.title ?? project.title;
      final file = mediaUrl(video.url ?? video.path);
      if (file.isNotEmpty) {
        out.add(_Video(file: true, src: file, title: title));
        continue;
      }
      final link = (video.externalUrl ?? '').trim();
      if (RegExp(r'^https?://', caseSensitive: false).hasMatch(link)) {
        out.add(_Video(file: false, src: link, title: title));
      }
    }
    return out;
  }
}

class _Video {
  const _Video({required this.file, required this.src, required this.title});
  final bool file;
  final String src;
  final String title;
}

// ---------------------------------------------------------------------------- pieces

class _DetailBar extends StatelessWidget {
  const _DetailBar({
    required this.solid,
    required this.backLabel,
    required this.onBack,
  });
  final bool solid;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final top = MediaQuery.paddingOf(context).top;
    final type = context.type;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Same frosted bar as the main top bar: scrolled text blurs away instead of ghosting through.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: solid ? 1 : 0),
      duration: const Duration(milliseconds: 380),
      curve: Brand.ease,
      builder: (context, t, child) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
          child: Container(
            height: top + kBarHeight,
            padding: EdgeInsets.fromLTRB(kGutter - 8, top, kGutter - 6, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    pal.bg.withValues(alpha: pal.dark ? 0.6 : 0.7),
                    pal.bg.withValues(alpha: 0.86),
                    t,
                  )!,
                  Color.lerp(
                    pal.bg.withValues(alpha: 0),
                    pal.bg.withValues(alpha: 0.86),
                    t,
                  )!,
                ],
              ),
              border: Border(
                bottom: BorderSide(color: pal.line.withValues(alpha: t)),
              ),
            ),
            child: child,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onBack();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.flip(
                        flipX: rtl,
                        child: const PathIcon(
                          Glyphs.arrowBack,
                          size: 22,
                          strokeWidth: 1.4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          tracked(context, backLabel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.label(
                            color: pal.text,
                            size: type.ar ? 15 : 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const BarActions(),
        ],
      ),
    );
  }
}

/// The photos laid out the way a Facebook post lays them out: the first one large on the right,
/// two stacked on the left, and "+N" over the last tile when there are more.
class _Mosaic extends StatelessWidget {
  const _Mosaic({
    required this.shots,
    required this.heroTag,
    required this.label,
    required this.onOpen,
  });
  final List<GalleryShot> shots;
  final String heroTag;
  final String label;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final extra = shots.length > 3 ? shots.length - 3 : 0;
    const gap = 5.0;

    Widget tile(int i, {bool lead = false, int more = 0}) {
      Widget image = AppImage(shots[i].src, cacheWidth: lead ? 1000 : 640);
      if (lead) image = Hero(tag: heroTag, child: image);
      return Semantics(
        button: true,
        excludeSemantics: true,
        label: more > 0 ? '$label +$more' : label,
        onTap: () => onOpen(i),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onOpen(i);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (more > 0)
                Container(
                  color: const Color(0x99000000),
                  alignment: Alignment.center,
                  child: Text(
                    '+$more',
                    textDirection: TextDirection.ltr,
                    style: context.type.latin(
                      size: 34,
                      weight: FontWeight.w300,
                      color: Colors.white,
                      spacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final Widget grid;
    if (shots.length == 1) {
      grid = tile(0, lead: true);
    } else if (shots.length == 2) {
      grid = Row(
        children: [
          Expanded(child: tile(1)),
          const SizedBox(width: gap),
          Expanded(flex: 13, child: tile(0, lead: true)),
        ],
      );
    } else {
      grid = Row(
        children: [
          Expanded(
            flex: 10,
            child: Column(
              children: [
                Expanded(child: tile(1)),
                const SizedBox(height: gap),
                Expanded(child: tile(2, more: extra)),
              ],
            ),
          ),
          const SizedBox(width: gap),
          Expanded(flex: 13, child: tile(0, lead: true)),
        ],
      );
    }

    return RevealImage(
      child: AspectRatio(
        aspectRatio: shots.length == 1 ? 1.1 : 0.98,
        child: Directionality(textDirection: TextDirection.ltr, child: grid),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = context.watch<LocaleController>();
    final c = locale.c;
    final type = context.type;
    final facts = <(String, String)>[
      if ((project.location ?? '').isNotEmpty)
        (c.locationLabel, project.location!),
      if (project.year != null) (c.yearLabel, '${project.year}'),
      if (project.area != null) (c.areaLabel, '${project.area} ${c.areaUnit}'),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: pal.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Wrap(
        spacing: 38,
        runSpacing: 22,
        children: [
          for (final fact in facts)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tracked(context, fact.$1), style: type.kicker()),
                const SizedBox(height: 8),
                Text(
                  fact.$2,
                  style: type
                      .title(type.ar ? 19 : 20)
                      .copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(color: pal.accentSoft.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: type
            .body(color: pal.accentSoft, size: type.ar ? 15 : 13.5)
            .copyWith(fontWeight: FontWeight.w400, height: 1.3),
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: pal.line),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.cardTop, pal.cardBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: pal.accentSoft.withValues(alpha: 0.4),
                  ),
                ),
                child: const PathIcon(Glyphs.user, size: 20, strokeWidth: 1.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.clientName,
                  style: type.title(17).copyWith(fontWeight: FontWeight.w400),
                ),
              ),
              Stars(value: review.rating, size: 14, gap: 3),
            ],
          ),
          const SizedBox(height: 14),
          Text(review.content, style: type.body(size: 15)),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGutter, 80, kGutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.asset('assets/brand/mark-gold.png', width: 64),
          ),
          const SizedBox(height: 34),
          Text(title, style: type.headline()),
          const SizedBox(height: 18),
          Text(text, style: type.body()),
        ],
      ),
    );
  }
}
