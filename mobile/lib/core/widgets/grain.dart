import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A fine film grain over the whole app. Removes the flat "digital black" and gives the
/// surfaces a printed feel, the same texture the website lays over its pages.
class GrainOverlay extends StatefulWidget {
  const GrainOverlay({super.key, this.opacity = 0.06, this.onLight = false});
  final double opacity;

  /// Dark specks for the beige look; pale specks for the black one.
  final bool onLight;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> {
  static final Map<bool, ui.Image> _cache = {};
  ui.Image? _tile;

  @override
  void initState() {
    super.initState();
    _tile = _cache[widget.onLight];
    if (_tile == null) _build(widget.onLight);
  }

  @override
  void didUpdateWidget(GrainOverlay old) {
    super.didUpdateWidget(old);
    if (old.onLight != widget.onLight) {
      _tile = _cache[widget.onLight];
      if (_tile == null) _build(widget.onLight);
    }
  }

  Future<void> _build(bool onLight) async {
    const side = 160;
    final random = math.Random(7);
    final pixels = Uint8List(side * side * 4);
    for (var i = 0; i < side * side; i++) {
      final shade = onLight ? random.nextInt(60) : 200 + random.nextInt(56);
      pixels[i * 4] = shade;
      pixels[i * 4 + 1] = shade;
      pixels[i * 4 + 2] = shade;
      pixels[i * 4 + 3] = random.nextInt(170);
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      side,
      side,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    final image = await done.future;
    _cache[onLight] = image;
    if (mounted && onLight == widget.onLight) setState(() => _tile = image);
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile;
    if (tile == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(tile, widget.opacity),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.tile, this.opacity);
  final ui.Image tile;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.ImageShader(
        tile,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..color = Colors.white.withValues(alpha: opacity)
      ..filterQuality = FilterQuality.none;
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawRect(Offset.zero & size, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.tile != tile || old.opacity != opacity;
}
