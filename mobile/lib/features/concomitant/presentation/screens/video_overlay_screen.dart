import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_preview_player.dart';

const String _originalKey = '__original__';

/// Original video vs. the annotated (overlay) video a technology produced.
/// No overlay is ever faked: if the backend did not generate one, say so.
class VideoOverlayScreen extends ConsumerWidget {
  final String analysisId;
  const VideoOverlayScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoAnalysisResultsProvider(analysisId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Annotated video')),
      body: SafeArea(
        child: ResponsiveBody(
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading analysis results...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
            ),
            data: (data) => data.hasResults
                ? _content(context, ref, data)
                : const SwaraEmptyState(title: 'No results are available.', icon: Icons.inbox_outlined),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, VideoAnalysisResults data) {
    final local = ref.watch(localVideoByAnalysisProvider)[analysisId];
    final hasOriginal = local?.path != null && !kIsWeb;
    final techs = data.technologies;

    final chosen = ref.watch(selectedTechnologyProvider(analysisId));
    String selected;
    if (chosen == _originalKey && hasOriginal) {
      selected = _originalKey;
    } else if (chosen != null && data.byKey(chosen) != null) {
      selected = chosen;
    } else {
      final withOverlay = techs.where((t) => t.overlayAvailable);
      selected = withOverlay.isNotEmpty ? withOverlay.first.key : (hasOriginal ? _originalKey : techs.first.key);
    }
    void select(String k) => ref.read(selectedTechnologyProvider(analysisId).notifier).state = k;

    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      Text('Video', style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.xs),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
        if (hasOriginal)
          ChoiceChip(label: const Text('Original video'), selected: selected == _originalKey, onSelected: (_) => select(_originalKey)),
        for (final t in techs)
          ChoiceChip(
            avatar: t.overlayAvailable ? const Icon(Icons.movie_filter_outlined, size: 16) : null,
            label: Text(t.name),
            selected: selected == t.key,
            onSelected: (_) => select(t.key),
          ),
      ]),
      const SizedBox(height: AppSpacing.lg),
      if (selected == _originalKey)
        VideoPreviewPlayer(key: ValueKey('orig-$analysisId'), filePath: local!.path)
      else
        _overlay(ref, data.byKey(selected)!),
      if (!hasOriginal) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          'The original video is only available on the device that uploaded it during this session; '
          'the server does not keep raw videos.',
          style: AppTextStyles.caption,
        ),
      ],
    ]);
  }

  Widget _overlay(WidgetRef ref, TechnologyResult t) {
    if (!t.overlayAvailable) {
      return SwaraCard(
        child: Column(children: [
          const Icon(Icons.videocam_off_outlined, color: AppColors.textLight, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text('Visualization unavailable for this technology.', style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.isCompleted
                ? 'No annotated video was generated. Turn on "Generate annotated video" under Research options before starting an analysis (supported technologies only).'
                : 'Reason: ${humanizeReason(t.reason)}',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }
    final src = ref.watch(overlaySourceProvider('$analysisId|${t.key}'));
    return src.when(
      loading: () => const SwaraLoadingWidget(message: 'Loading annotated video...'),
      error: (e, _) => SwaraErrorWidget(message: VideoAnalysisException.from(e).message),
      data: (s) => VideoPreviewPlayer(key: ValueKey(s.url), networkUrl: s.url, httpHeaders: s.headers),
    );
  }
}
