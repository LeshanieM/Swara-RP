import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Step 4: technology results hub. Detail, comparison, timeline, annotated
/// video and evaluation metrics each have their own screen.
class VideoAnalysisResultsScreen extends ConsumerWidget {
  final String analysisId;
  const VideoAnalysisResultsScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoAnalysisResultsProvider(analysisId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Computer Vision Analysis'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveBody(
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading analysis results...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
            ),
            data: (data) => _content(context, data),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, VideoAnalysisResults data) {
    if (!data.hasResults) {
      if (data.isFailed) {
        return SwaraErrorWidget(
          message: 'The analysis failed.\n${humanizeReason(data.error)}',
          onRetry: () => context.pushReplacement('/c2/video/upload'),
        );
      }
      return const SwaraEmptyState(
        title: 'No results are available.',
        subtitle: 'The analysis returned no technology results.',
        icon: Icons.inbox_outlined,
      );
    }

    final meta = data.videoMeta;
    final base = '/c2/video/results/$analysisId';
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      SwaraCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.videocam_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(data.videoFilename ?? 'Analyzed video',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleMedium),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
            if (meta.hasDuration)
              StatusPill(label: fmtSeconds(meta.duration, digits: 1), color: AppColors.primaryDeep, icon: Icons.timer_outlined),
            if (meta.fps != null && meta.fps! > 0)
              StatusPill(label: '${meta.fps!.toStringAsFixed(0)} fps', color: AppColors.primaryDeep),
            if (meta.resolution != null) StatusPill(label: meta.resolution!, color: AppColors.primaryDeep),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
            StatusPill(
                label: '${data.countWhere(TechStatus.completed)} completed',
                color: TechStatus.completed.color,
                icon: TechStatus.completed.icon),
            if (data.countWhere(TechStatus.unavailable) > 0)
              StatusPill(
                  label: '${data.countWhere(TechStatus.unavailable)} unavailable',
                  color: TechStatus.unavailable.color,
                  icon: TechStatus.unavailable.icon),
            if (data.countWhere(TechStatus.failed) > 0)
              StatusPill(
                  label: '${data.countWhere(TechStatus.failed)} failed',
                  color: TechStatus.failed.color,
                  icon: TechStatus.failed.icon),
          ]),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      ResearchNote(data.comparisonNote ??
          'Research output: visual-feature movement events from each technology. '
              'Not a diagnosis. No technology is ranked or scored.'),
      const SectionTitle('Explore'),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - AppSpacing.md) / 2;
        Widget tile(IconData icon, String label, String route) => SizedBox(
              width: w,
              child: SwaraCard(
                onTap: () => context.push('$base/$route'),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  Icon(icon, color: AppColors.primaryDeep),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, style: AppTextStyles.label)),
                ]),
              ),
            );
        return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
          tile(Icons.compare_arrows_rounded, 'Comparison', 'compare'),
          tile(Icons.timeline_rounded, 'Event timeline', 'timeline'),
          tile(Icons.movie_filter_outlined, 'Annotated video', 'overlay'),
          tile(Icons.fact_check_outlined, 'Research metrics', 'metrics'),
        ]);
      }),
      const SectionTitle('Technologies'),
      for (final t in data.technologies) _techCard(context, t, base),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }

  Widget _techCard(BuildContext context, TechnologyResult t, String base) {
    final supported = t.behaviors.entries.where((e) => e.value.isSupported).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SwaraCard(
        onTap: () => context.push('$base/tech/${t.key}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            TechStatusIcon(t.status),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(t.name, style: AppTextStyles.heading3)),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.isCompleted
                ? 'Completed${t.processingTime != null ? ' - ${fmtSeconds(t.processingTime)}' : ''}'
                : t.status.label,
            style: AppTextStyles.label.copyWith(color: t.status.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (t.isCompleted) ...[
            if (supported.isEmpty)
              Text('No supported behaviors were reported.', style: AppTextStyles.bodySmall)
            else
              for (final e in supported)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: behaviorColor(e.key), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(behaviorEventsText(e.key, e.value.eventCount), style: AppTextStyles.bodySmall.copyWith(color: AppColors.text)),
                  ]),
                ),
          ] else
            Text('Reason: ${humanizeReason(t.reason)}', style: AppTextStyles.bodySmall),
        ]),
      ),
    );
  }
}
