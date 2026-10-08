import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'video_analysis_ui.dart';

/// Video player with play/pause, scrubbing and duration. Plays either a local
/// file ([filePath], native only) or a network URL with optional headers.
class VideoPreviewPlayer extends StatefulWidget {
  final String? filePath;
  final String? networkUrl;
  final Map<String, String> httpHeaders;

  /// Called once the real duration is known.
  final ValueChanged<Duration>? onDuration;
  final double maxHeight;

  const VideoPreviewPlayer({
    super.key,
    this.filePath,
    this.networkUrl,
    this.httpHeaders = const {},
    this.onDuration,
    this.maxHeight = 300,
  }) : assert(filePath != null || networkUrl != null);

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant VideoPreviewPlayer old) {
    super.didUpdateWidget(old);
    if (old.filePath != widget.filePath || old.networkUrl != widget.networkUrl) {
      final previous = _controller;
      _controller = null;
      previous?.dispose();
      setState(() {
        _loading = true;
        _error = null;
      });
      _init();
    }
  }

  Future<void> _init() async {
    VideoPlayerController? created;
    try {
      created = widget.filePath != null
          ? VideoPlayerController.file(File(widget.filePath!))
          : VideoPlayerController.networkUrl(Uri.parse(widget.networkUrl!), httpHeaders: widget.httpHeaders);
      await created.initialize();
    } catch (_) {
      await created?.dispose();
      if (mounted && !_disposed) {
        setState(() {
          _loading = false;
          _error = 'This video cannot be played on this device.';
        });
      }
      return;
    }
    final c = created!;
    if (!mounted || _disposed) {
      await c.dispose();
      return;
    }
    widget.onDuration?.call(c.value.duration);
    setState(() {
      _controller = c;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    }
    final c = _controller;
    if (_error != null || c == null) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadii.mdAll),
        child: Text(_error ?? 'Video unavailable.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      );
    }
    final ratio = c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: ClipRRect(
          borderRadius: AppRadii.mdAll,
          child: AspectRatio(
            aspectRatio: ratio,
            child: Stack(alignment: Alignment.center, children: [
              VideoPlayer(c),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: c,
                builder: (_, v, __) => AnimatedOpacity(
                  opacity: v.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (_, v, __) => Row(children: [
          IconButton(
            tooltip: v.isPlaying ? 'Pause' : 'Play',
            onPressed: () => v.isPlaying ? c.pause() : c.play(),
            icon: Icon(v.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: AppColors.primary, size: 34),
          ),
          Expanded(
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: AppColors.primaryLight,
                backgroundColor: AppColors.divider,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${fmtClock(v.position)} / ${fmtClock(v.duration)}', style: AppTextStyles.caption),
        ]),
      ),
    ]);
  }
}
