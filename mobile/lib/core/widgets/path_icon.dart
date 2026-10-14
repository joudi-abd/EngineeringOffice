import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';

final Map<String, Path> _parsed = {};

Path _path(String data) =>
    _parsed.putIfAbsent(data, () => parseSvgPathData(data));

/// A 24×24 SVG path drawn as a round-capped stroke (or filled), so every icon in the app
/// shares one hand: the same one the website uses.
class PathIcon extends StatelessWidget {
  const PathIcon(
    this.data, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.5,
    this.filled = false,
    this.viewBox = 24,
  });

  final String data;
  final double viewBox;
  final double size;

  /// Defaults to the soft gold of the current look.
  final Color? color;
  final double strokeWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _PathPainter(
        data,
        color ?? context.pal.accentSoft,
        strokeWidth,
        filled,
        viewBox,
      ),
    ),
  );
}

class _PathPainter extends CustomPainter {
  _PathPainter(
    this.data,
    this.color,
    this.strokeWidth,
    this.filled,
    this.viewBox,
  );
  final double viewBox;
  final String data;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_path(data), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.data != data ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.filled != filled ||
      old.viewBox != viewBox;
}

/// Hand-drawn glyphs used by the app chrome (24×24 stroke paths).
class Glyphs {
  static const home = 'M3.5 11L12 4l8.5 7M6 9.5V20h12V9.5M10 20v-5h4v5';
  static const about =
      'M12 2.5a1.6 1.6 0 1 0 0 3.2 1.6 1.6 0 0 0 0-3.2zM11 5.4L5.5 20.5M13 5.4l5.5 15.1M8.2 14.5h7.6';
  static const services = 'M4 4.5h16v15H4zM4 9.5h16M9.5 9.5v10M13 13.5h4';
  static const projects =
      'M5 21V5l9-2v18M14 8h5v13M3.5 21h17M9 8h1M9 12h1M9 16h1';
  static const contact = 'M4 6.5h16v11H4zM4.5 7l7.5 6 7.5-6';
  static const arrow = 'M5 12h14M13.5 6.5 19 12l-5.5 5.5';
  static const arrowBack = 'M19 12H5M10.5 6.5 5 12l5.5 5.5';
  static const chevronLeft = 'M15 5.5 8.5 12 15 18.5';
  static const chevronRight = 'M9 5.5 15.5 12 9 18.5';
  static const close = 'M6 6l12 12M18 6 6 18';
  static const play = 'M8 5.5v13l11-6.5z';
  static const phone =
      'M5 4h4l1.5 4-2 1.3a11 11 0 0 0 5.2 5.2L15 12.5l4 1.5v4a2 2 0 0 1-2 2A13 13 0 0 1 3 6a2 2 0 0 1 2-2z';
  static const whatsapp =
      'M12 3.5a8.5 8.5 0 0 0-7.3 12.9L3.5 20.5l4.2-1.1A8.5 8.5 0 1 0 12 3.5zM9 8.5c.3 3 2.5 5.2 6 6.5l1.2-1.4-2-1-.9.8c-.9-.4-1.6-1.100-2-2l.8-.9-1-2z';
  static const pin =
      'M12 21s6.5-5.6 6.5-11a6.5 6.5 0 0 0-13 0c0 5.400 6.500 11 6.500 11zM12 12a2.300 2.300 0 1 0 0-4.600 2.300 2.300 0 0 0 0 4.600z';
  static const clock =
      'M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 0 0 0-17zM12 7.500V12l3 2';
  static const mail = 'M4 6.5h16v11H4zM4.500 7l7.500 6 7.500-6';
  static const globe =
      'M12 3.500a8.500 8.500 0 1 0 0 17 8.500 8.500 0 0 0 0-17zM3.500 12h17M12 3.500c2.500 2.600 3.500 5.400 3.500 8.500s-1 5.900-3.500 8.500c-2.500-2.600-3.500-5.400-3.500-8.500s1-5.900 3.500-8.500z';
  static const facebook =
      'M14.2 21v-8h2.7l.5-3.3h-3.2V7.6c0-.9.4-1.7 1.8-1.7h1.5V3.1c-.3 0-1.3-.1-2.4-.1-2.5 0-4.1 1.5-4.1 4.2v2.5H8.2V13h2.8v8z';
  static const instagram =
      'M7.5 3.5h9a4 4 0 0 1 4 4v9a4 4 0 0 1-4 4h-9a4 4 0 0 1-4-4v-9a4 4 0 0 1 4-4zM12 8.3a3.7 3.7 0 1 0 0 7.4 3.7 3.7 0 0 0 0-7.4zM17.2 6.9h.01';
  static const star =
      'M10 2.2 12.1 7.2l5.5.5-4.2 3.6 1.3 5.3L10 13.8 5.3 16.6l1.3-5.3L2.4 7.7l5.5-.5z';
  static const user =
      'M12 4.9a3.1 3.1 0 1 0 0 6.2 3.1 3.1 0 0 0 0-6.2zM5.6 19.2c1.1-2.900 3.300-4.300 6.400-4.300s5.300 1.400 6.400 4.300';
  // Lucide (lucide.dev, ISC): the day / night switch.
  static const sun =
      'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zM12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41';
  static const moon = 'M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z';
  static const check = 'M5 12.500l4.500 4.500L19 7.500';
}
