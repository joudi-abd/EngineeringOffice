import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';

/// Fades and lifts its child into place the first time it scrolls into view.
/// Mirrors the website's `.rv` reveal. Respects the system "reduce motion" setting.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dy = 26,
    this.duration = const Duration(milliseconds: 900),
    this.threshold = 0.94,
  });

  final Widget child;
  final Duration delay;
  final double dy;
  final Duration duration;

  /// Fraction of the viewport height the child's top must pass before it plays.
  final double threshold;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Brand.ease,
  );
  ScrollPosition? _position;
  Timer? _timer;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _played = true;
      _controller.value = 1;
      return;
    }
    _position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    _position?.addListener(_onScroll);
    _check();
  }

  bool _queued = false;

  /// Scroll notifications arrive before the new offset is laid out, so measure after the frame.
  /// Otherwise the last frame of a scroll leaves a block that just crossed the line still hidden.
  void _onScroll() {
    if (_queued || _played) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      _check();
    });
  }

  void _check() {
    if (_played || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final height = MediaQuery.sizeOf(context).height;
    if (top > height * widget.threshold) return;
    _played = true;
    _position?.removeListener(_onScroll);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.dy),
          child: child,
        ),
      ),
    );
  }
}

/// A clip-from-top image reveal, like the website's `.rv-img`.
class RevealImage extends StatefulWidget {
  const RevealImage({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });
  final Widget child;
  final Duration delay;

  @override
  State<RevealImage> createState() => _RevealImageState();
}

class _RevealImageState extends State<RevealImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Brand.easeInOut,
  );
  ScrollPosition? _position;
  Timer? _timer;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _played = true;
        _controller.value = 1;
        return;
      }
      _position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
      _position?.addListener(_onScroll);
      _check();
    });
  }

  bool _queued = false;

  /// Scroll notifications arrive before the new offset is laid out, so measure after the frame.
  /// Otherwise the last frame of a scroll leaves a block that just crossed the line still hidden.
  void _onScroll() {
    if (_queued || _played) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      _check();
    });
  }

  void _check() {
    if (_played || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    if (box.localToGlobal(Offset.zero).dy >
        MediaQuery.sizeOf(context).height * 0.96) {
      return;
    }
    _played = true;
    _position?.removeListener(_onScroll);
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) =>
        ClipRect(clipper: _TopClip(_curve.value), child: child),
  );
}

class _TopClip extends CustomClipper<Rect> {
  _TopClip(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    0,
    0,
    size.width,
    (size.height * t).clamp(2.0, size.height),
  );

  @override
  bool shouldReclip(_TopClip old) => old.t != t;
}
