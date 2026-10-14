import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';

class GalleryShot {
  const GalleryShot({required this.src, required this.alt});
  final String src;
  final String alt;
}

/// Full-screen viewer: swipe left / right between photos, pinch to zoom, double-tap to zoom in.
class GalleryViewer extends StatefulWidget {
  const GalleryViewer({
    super.key,
    required this.shots,
    required this.initial,
    required this.closeLabel,
  });
  final List<GalleryShot> shots;
  final int initial;
  final String closeLabel;

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late final PageController _page = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  final Map<int, TransformationController> _zoom = {};
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _page.dispose();
    for (final controller in _zoom.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _controllerFor(int index) {
    return _zoom.putIfAbsent(index, () {
      final controller = TransformationController();
      controller.addListener(() {
        final zoomed = controller.value.getMaxScaleOnAxis() > 1.02;
        if (index == _index && zoomed != _zoomed) {
          setState(() => _zoomed = zoomed);
        }
      });
      return controller;
    });
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.shots.length) return;
    _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Brand.ease,
    );
  }

  void _doubleTap(int index, Offset position) {
    final controller = _controllerFor(index);
    if (controller.value.getMaxScaleOnAxis() > 1.02) {
      controller.value = Matrix4.identity();
    } else {
      const scale = 2.6;
      controller.value = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final total = widget.shots.length;
    Offset lastTap = Offset.zero;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The viewer is black in both looks, so the bar icons must stay light even in the day theme.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: PageView.builder(
                controller: _page,
                itemCount: total,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: (value) => setState(() {
                  _index = value;
                  _zoomed =
                      _controllerFor(value).value.getMaxScaleOnAxis() > 1.02;
                }),
                itemBuilder: (context, i) {
                  final shot = widget.shots[i];
                  return GestureDetector(
                    onDoubleTapDown: (details) =>
                        lastTap = details.localPosition,
                    onDoubleTap: () => _doubleTap(i, lastTap),
                    child: InteractiveViewer(
                      transformationController: _controllerFor(i),
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: shot.src,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          fadeInDuration: const Duration(milliseconds: 420),
                          placeholder: (_, _) => const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.2,
                                color: Brand.goldSoft,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Center(
                            child: Opacity(
                              opacity: 0.3,
                              child: Image.asset(
                                'assets/brand/mark-gold.png',
                                width: 80,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // close
            PositionedDirectional(
              top: top + 10,
              end: 16,
              child: Semantics(
                button: true,
                label: widget.closeLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x66000000),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const PathIcon(
                      Glyphs.close,
                      size: 20,
                      color: Colors.white,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // counter
            if (total > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottom + 22,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      '${_index + 1} / $total',
                      textDirection: TextDirection.ltr,
                      style: type.latin(
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        spacing: 3,
                      ),
                    ),
                  ),
                ),
              ),

            // arrows
            if (total > 1 && !_zoomed) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _Arrow(
                    glyph: Glyphs.chevronLeft,
                    enabled: _index > 0,
                    onTap: () => _step(-1),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _Arrow(
                    glyph: Glyphs.chevronRight,
                    enabled: _index < total - 1,
                    onTap: () => _step(1),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.glyph,
    required this.enabled,
    required this.onTap,
  });
  final String glyph;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: enabled ? 1 : 0,
    duration: const Duration(milliseconds: 240),
    child: IgnorePointer(
      ignoring: !enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x4D000000),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: PathIcon(
            glyph,
            size: 20,
            color: Colors.white,
            strokeWidth: 1.5,
          ),
        ),
      ),
    ),
  );
}
