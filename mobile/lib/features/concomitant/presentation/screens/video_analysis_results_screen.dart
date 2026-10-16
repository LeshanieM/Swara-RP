import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Results for the TMMF feature-extraction workflow. This screen deliberately
/// does not present movement signals as validated FG/HM predictions.
class VideoAnalysisResultsScreen extends ConsumerWidget {
  final String analysisId;
  const VideoAnalysisResultsScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoAnalysisResultsProvider(analysisId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Movement feature results'),
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
            loading: () => const SwaraLoadingWidget(message: 'Loading movement features...'),
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
    final analysis = data.byKey('mediapipe');
    if (analysis == null || !analysis.isCompleted) {
      return SwaraErrorWidget(
        message: analysis == null
            ? 'No MediaPipe movement analysis was returned.'
            : 'Movement feature extraction did not complete. ${humanizeReason(analysis.reason)}',
        onRetry: () => context.pushReplacement('/c2/video/upload'),
      );
    }

    final tmmf = analysis.tmmf;
    if (tmmf == null || !tmmf.hasWindows) {
      return const SwaraEmptyState(
        title: 'No temporal features were returned.',
        subtitle: 'Try another video with a clearly visible face.',
        icon: Icons.face_retouching_off_outlined,
      );
    }

    final meta = data.videoMeta;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
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
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              StatusPill(label: '${tmmf.windows.length} windows', color: AppColors.primaryDeep,
                  icon: Icons.view_week_outlined),
              if (tmmf.windowSeconds != null)
                StatusPill(label: '${tmmf.windowSeconds!.toStringAsFixed(0)} s windows',
                    color: AppColors.primaryDeep),
              if (tmmf.overlap != null)
                StatusPill(label: '${(tmmf.overlap! * 100).round()}% overlap', color: AppColors.primaryDeep),
              if (tmmf.targetFps != null)
                StatusPill(label: '${tmmf.targetFps!.toStringAsFixed(0)} sampled fps', color: AppColors.primaryDeep),
              if (meta.resolution != null)
                StatusPill(label: meta.resolution!, color: AppColors.primaryDeep),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        const ResearchNote(
          'These are eye, lip, jaw, and head movement features over time. '
          'This workflow does not yet produce validated Facial Grimace (FG) or Head Movement (HM) predictions.\n'
          'මෙහි දැක්වෙන්නේ කාලයත් සමඟ ඇස්, තොල්, හකු සහ හිස චලන ලක්ෂණයි. මේවා තහවුරු කළ FG/HM අනාවැකි නොවේ.',
          icon: Icons.science_outlined,
        ),
        const SectionTitle('Movement feature summary'),
        _channelGrid(tmmf),
        const SizedBox(height: AppSpacing.md),
        _windowPreview(tmmf),
        const SizedBox(height: AppSpacing.md),
        SwaraCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tracking', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${analysis.tracking.processedFrames ?? 0} frames analyzed'
              '${analysis.tracking.missingFrames == null ? '' : ' · ${analysis.tracking.missingFrames} frames without a face'}',
              style: AppTextStyles.bodySmall,
            ),
            if (analysis.processingTime != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Processing time: ${fmtSeconds(analysis.processingTime)}',
                    style: AppTextStyles.caption),
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

  Widget _channelGrid(TmmfResult tmmf) {
    const channels = [
      ('eye', 'Eye movement', Icons.remove_red_eye_outlined),
      ('lip', 'Lip movement', Icons.sentiment_satisfied_alt_outlined),
      ('jaw', 'Jaw movement', Icons.face_outlined),
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
              child: _channelCard(tmmf, key, label, icon),
            ),
        ],
      );
    });
  }

  Widget _channelCard(TmmfResult tmmf, String key, String label, IconData icon) {
    final meanKey = '${key}_mean';
    final velocityKey = '${key}_max_velocity';
    final means = tmmf.windows.map((w) => w.features[meanKey]).whereType<double>().toList();
    final velocities = tmmf.windows.map((w) => w.features[velocityKey]).whereType<double>().toList();
    final average = means.isEmpty ? null : means.reduce((a, b) => a + b) / means.length;
    final peak = velocities.isEmpty ? null : velocities.reduce((a, b) => a > b ? a : b);
    return SwaraCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
        ]),
        const SizedBox(height: AppSpacing.md),
        _metricLine('Average window signal', average),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Peak window velocity', peak),
      ]),
    );
  }

  Widget _metricLine(String label, double? value) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value == null ? '—' : value.toStringAsFixed(4), style: AppTextStyles.label),
        ],
      );

  Widget _windowPreview(TmmfResult tmmf) {
    final preview = tmmf.windows.take(8).toList(growable: false);
    return SwaraCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.view_timeline_outlined, color: AppColors.primaryDeep),
        title: Text('Window preview', style: AppTextStyles.titleMedium),
        subtitle: Text('Showing ${preview.length} of ${tmmf.windows.length} windows', style: AppTextStyles.caption),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [
          for (var i = 0; i < preview.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('Window ${i + 1}', style: AppTextStyles.label),
              subtitle: Text(
                '${preview[i].startTime.toStringAsFixed(1)}–${preview[i].endTime.toStringAsFixed(1)} s\n'
                'Eye ${_short(preview[i].features['eye_mean'])} · '
                'Lip ${_short(preview[i].features['lip_mean'])} · '
                'Jaw ${_short(preview[i].features['jaw_mean'])} · '
                'Head ${_short(preview[i].features['head_mean'])}',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }

  String _short(double? value) => value == null ? '—' : value.toStringAsFixed(2);
}
