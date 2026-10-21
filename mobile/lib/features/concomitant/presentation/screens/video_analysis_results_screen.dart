import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Results of the secondary-behaviour analysis: for each stutter moment, whether the face (FG)
/// or the head (HM) moved unusually compared with the child's own fluent speech.
class VideoAnalysisResultsScreen extends ConsumerWidget {
  final String analysisId;
  const VideoAnalysisResultsScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoAnalysisResultsProvider(analysisId));
    return Scaffold(
      backgroundColor: AppColors.groundAdult,
      appBar: AppBar(
        title: const Text('Movement analysis results'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
          ),
        ],
      ),
      body: CalmSceneBackground(
        child: SafeArea(
        child: ResponsiveBody(
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading the analysis...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
            ),
            data: (data) => _content(context, data),
          ),
        ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, VideoAnalysis data) {
    if (data.isNotAssessed) {
      return const SwaraEmptyState(
        title: 'Not assessed',
        subtitle: 'No video was recorded, so secondary behaviours were not assessed.',
        icon: Icons.videocam_off_outlined,
      );
    }
    final result = data.result;
    if (!data.isCompleted || result == null) {
      return SwaraErrorWidget(
        message: data.isFailed
            ? 'The analysis did not complete. ${humanizeReason(data.errorMessage)}'
            : 'The analysis is still running.',
        onRetry: () => context.pushReplacement(data.isFailed ? '/c2/video/upload' : '/c2/video/process/${data.id}'),
      );
    }
    if (result.moments.isEmpty) {
      return SwaraEmptyState(
        title: 'No stutter moments were found.',
        subtitle: result.warnings.isNotEmpty
            ? result.warnings.first
            : 'Secondary behaviours are only checked during stutter moments.',
        icon: Icons.face_retouching_off_outlined,
      );
    }

    final meta = result.video;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SwaraCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.videocam_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(data.filename ?? 'Analyzed video',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleMedium),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              StatusPill(label: '${result.momentsTotal} stutter moments', color: AppColors.primaryDeep,
                  icon: Icons.view_week_outlined),
              if (meta.duration != null)
                StatusPill(label: fmtSeconds(meta.duration, digits: 0), color: AppColors.primaryDeep),
              if (meta.analysedFps != null)
                StatusPill(label: '${meta.analysedFps!.toStringAsFixed(0)} sampled fps', color: AppColors.primaryDeep),
              if (meta.resolution != null)
                StatusPill(label: meta.resolution!, color: AppColors.primaryDeep),
              if (result.detectorFallback)
                const StatusPill(label: 'Fallback detector', color: AppColors.warning),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _summaryCard(result),
        const SizedBox(height: AppSpacing.md),
        ResearchNote(
          'Each signal is compared with this child\'s own fluent speech'
          '${result.baselineSource == 'whole_recording' ? ' (estimated from the whole video, as there was too little fluent speech)' : ''}. '
          'Values are in standard deviations from that normal. This is a research estimate for an SLP to review, not a diagnosis.',
          icon: Icons.science_outlined,
        ),
        const SectionTitle('Movement at stutter moments'),
        _channelGrid(result),
        const SizedBox(height: AppSpacing.md),
        _momentList(result),
        const SizedBox(height: AppSpacing.md),
        SwaraCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tracking', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${meta.framesAnalysed ?? 0} frames analyzed'
              '${meta.missingFrames == null ? '' : ' · ${meta.missingFrames} frames without a face'}',
              style: AppTextStyles.bodySmall,
            ),
            if (result.processingSeconds != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Processing time: ${fmtSeconds(result.processingSeconds)}',
                    style: AppTextStyles.caption),
              ),
            for (final w in result.warnings)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('⚠ $w', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: () => context.pushReplacement('/c2/video/upload'),
          icon: const Icon(Icons.add),
          label: const Text('Analyze another video'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _summaryCard(C2Result r) {
    final (label, color) = switch (r.hasSecondaryBehaviors) {
      true => ('Secondary behaviours seen', AppColors.warning),
      false => ('No secondary behaviours seen', AppColors.success),
      null => ('Could not be assessed', AppColors.textLight),
    };
    return SwaraCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.face_retouching_natural, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.titleMedium.copyWith(color: color))),
        ]),
        const SizedBox(height: AppSpacing.md),
        _metricLine('Moments with a behaviour', '${r.momentsWithBehaviour} of ${r.momentsAssessed} assessed'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Facial grimace (FG)', '${r.fgCount}'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Head movement (HM)', '${r.hmCount}'),
        if (r.concomitantScore != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _metricLine('Concomitant score', r.concomitantScore!.toStringAsFixed(2)),
        ],
      ]),
    );
  }

  Widget _channelGrid(C2Result r) {
    final channels = const [
      ('eye', 'Eye movement', Icons.remove_red_eye_outlined),
      ('lip', 'Lip movement', Icons.sentiment_satisfied_alt_outlined),
      ('jaw', 'Jaw movement', Icons.face_outlined),
      ('cheek', 'Cheek movement', Icons.mood_outlined),
      ('head', 'Head movement', Icons.accessibility_new_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final width = wide ? (constraints.maxWidth - AppSpacing.md) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final (key, label, icon) in channels)
            SizedBox(
              width: width,
              child: _channelCard(r, key, label, icon),
            ),
        ],
      );
    });
  }

  Widget _channelCard(C2Result r, String key, String label, IconData icon) {
    final (mean, peak) = r.deviationOf(key);
    final exceeded = r.exceedCount(key);
    return SwaraCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
          if (exceeded > 0) StatusPill(label: '$exceeded unusual', color: AppColors.warning),
        ]),
        const SizedBox(height: AppSpacing.md),
        _metricLine('Mean deviation', mean == null ? '—' : '${mean.toStringAsFixed(1)} SD'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Peak deviation', peak == null ? '—' : '${peak.toStringAsFixed(1)} SD'),
      ]),
    );
  }

  Widget _metricLine(String label, String value) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value, style: AppTextStyles.label),
        ],
      );

  Widget _momentList(C2Result r) {
    return SwaraCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.view_timeline_outlined, color: AppColors.primaryDeep),
        title: Text('Stutter moments', style: AppTextStyles.titleMedium),
        subtitle: Text('${r.momentsAssessed} of ${r.momentsTotal} could be assessed', style: AppTextStyles.caption),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [
          for (final m in r.moments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Row(children: [
                Expanded(
                  child: Text(
                    'Moment ${m.index + 1} · ${m.start.toStringAsFixed(1)}–${m.end.toStringAsFixed(1)} s'
                    '${m.types.isEmpty ? '' : ' · ${m.types.map((t) => t.replaceAll('_', ' ')).join(', ')}'}',
                    style: AppTextStyles.label,
                  ),
                ),
                if (!m.assessed) const StatusPill(label: 'Face not visible', color: AppColors.textLight),
                if (m.fg.present) const StatusPill(label: 'FG', color: AppColors.warning),
                if (m.hm.present) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const StatusPill(label: 'HM', color: AppColors.warning),
                ],
              ]),
              subtitle: Text(
                m.explanation.isNotEmpty
                    ? m.explanation.join('\n')
                    : (m.assessed ? 'Within this child\'s normal movement.' : 'Too little of the face was visible.'),
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}
