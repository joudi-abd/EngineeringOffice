import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';

/// The office's services drifting past in large outlined type (the website's marquee).
class ServiceMarquee extends StatefulWidget {
  const ServiceMarquee({super.key, required this.items});
  final List<String> items;

  @override
  State<ServiceMarquee> createState() => _ServiceMarqueeState();
}

class _ServiceMarqueeState extends State<ServiceMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 50),
  )..addListener(_tick);
  final ScrollController _scroll = ScrollController();
  final GlobalKey _first = GlobalKey();
  bool _started = false;

  void _tick() {
    if (!_scroll.hasClients) return;
    final width = _first.currentContext?.size?.width;
    if (width == null || width <= 0) return;
    _scroll.jumpTo(_ticker.value * width);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _ticker.stop();
      _started = false;
    } else if (!_started) {
      _started = true;
      _ticker.repeat();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    final style = type.ar
        ? type
              .display(40)
              .copyWith(
                fontWeight: FontWeight.w300,
                color: pal.text.withValues(alpha: 0.2),
                height: 1.4,
              )
        : TextStyle(
            fontFamily: 'NeuePower',
            fontSize: 44,
            fontWeight: FontWeight.w300,
            height: 1.3,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = pal.accentSoft.withValues(alpha: 0.5),
          );

    // Enough words that one run is wider than the screen, however few services exist.
    final repeats = widget.items.isEmpty ? 0 : (6 / widget.items.length).ceil();
    final words = [for (var i = 0; i < repeats; i++) ...widget.items];

    Widget run({Key? key}) => Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in words)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 36),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item,
                  style: style,
                  textDirection: type.ar
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
                const SizedBox(width: 36),
                Transform.rotate(
                  angle: 0.7853981634,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: pal.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return Container(
      height: 104,
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: pal.line)),
      ),
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                run(key: _first),
                run(),
                run(),
                run(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
