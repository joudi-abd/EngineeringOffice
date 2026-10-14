import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';

class _PlayDisc extends StatelessWidget {
  const _PlayDisc();
  static const double size = 68;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0x66000000),
      border: Border.all(color: Brand.goldSoft.withValues(alpha: 0.8)),
    ),
    child: Padding(
      padding: const EdgeInsets.only(left: 3),
      child: PathIcon(
        Glyphs.play,
        size: size * 0.36,
        color: Brand.goldSoft,
        filled: true,
      ),
    ),
  );
}

/// A video uploaded to the server: plays inside the app (native player, no WebView).
class FileVideoTile extends StatefulWidget {
  const FileVideoTile({super.key, required this.url, required this.title});
  final String url;
  final String title;

  @override
  State<FileVideoTile> createState() => _FileVideoTileState();
}

class _FileVideoTileState extends State<FileVideoTile> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _loading = false;

  Future<void> _start() async {
    if (_loading) return;
    setState(() => _loading = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setLooping(false);
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () => openExternal(Uri.parse(widget.url)),
          child: const _Poster(child: _PlayDisc()),
        ),
      );
    }
    if (controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: _start,
          child: _Poster(
            child: _loading
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.2,
                      color: Brand.goldSoft,
                    ),
                  )
                : const _PlayDisc(),
          ),
        ),
      );
    }
    final value = controller.value;
    final progress = value.duration.inMilliseconds == 0
        ? 0.0
        : value.position.inMilliseconds / value.duration.inMilliseconds;
    return AspectRatio(
      aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          value.isPlaying ? controller.pause() : controller.play();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black, child: VideoPlayer(controller)),
            AnimatedOpacity(
              opacity: value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 260),
              child: const Center(child: _PlayDisc()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: Colors.white24,
                color: Brand.goldSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A YouTube / Vimeo / other link: a still with a play button that opens the phone's own app.
class LinkVideoTile extends StatelessWidget {
  const LinkVideoTile({
    super.key,
    required this.link,
    required this.title,
    required this.label,
  });
  final String link;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ref = videoRef(link);
    final thumb = ref?.kind == 'youtube'
        ? 'https://img.youtube.com/vi/${ref!.id}/hqdefault.jpg'
        : '';
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          openExternal(Uri.parse(link));
        },
        child: Semantics(
          button: true,
          label: '$label: $title',
          child: Stack(
            fit: StackFit.expand,
            children: [
              thumb.isNotEmpty
                  ? AppImage(thumb, cacheWidth: 900)
                  : const _Poster(child: SizedBox.shrink()),
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x33000000)),
              ),
              const Center(child: _PlayDisc()),
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: 14,
                child: Text(
                  tracked(context, label),
                  style: context.type.meta(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.2),
        radius: 0.9,
        colors: [Color(0xFF1A1613), Color(0xFF0B0A09)],
      ),
    ),
    child: Center(child: child),
  );
}
