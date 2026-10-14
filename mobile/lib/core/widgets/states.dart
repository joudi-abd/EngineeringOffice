import 'package:flutter/material.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';

/// First thing the user sees while the content loads: the gold mark breathing over black.
class BrandLoader extends StatefulWidget {
  const BrandLoader({super.key});

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return ColoredBox(
      color: pal.bg,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Brand.easeInOut.transform(_controller.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: 0.45 + 0.55 * t,
                  child: Image.asset('assets/brand/mark-gold.png', width: 92),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 120,
                  height: 1,
                  color: pal.line,
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: 0.25 + 0.75 * t,
                    child: Container(height: 1, color: pal.accent),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Shown when nothing could be loaded (offline, server down).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.text,
    required this.action,
    required this.onRetry,
  });
  final String title;
  final String text;
  final String action;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    // A Scaffold (not a bare ColoredBox) so the texts get Material's text style, not the
    // yellow double underline Flutter paints for text with no Material ancestor.
    return Scaffold(
      backgroundColor: context.pal.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kGutter + 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Image.asset('assets/brand/mark-gold.png', width: 64),
                ),
                const SizedBox(height: 38),
                Text(title, style: type.headline(type.ar ? 30 : 36)),
                const SizedBox(height: 18),
                Text(text, style: type.body()),
                const SizedBox(height: 40),
                GoldButton(label: action, onTap: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet one-line note for empty lists.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Text(text, style: context.type.body()),
  );
}
