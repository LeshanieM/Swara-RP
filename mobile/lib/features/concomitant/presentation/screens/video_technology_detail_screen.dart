import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Detailed result of ONE technology: status, tracking, and every behavior.
class VideoTechnologyDetailScreen extends ConsumerWidget {
  final String analysisId;
  final String techKey;
  const VideoTechnologyDetailScreen({super.key, required this.analysisId, required this.techKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoAnalysisResultsProvider(analysisId));
    final tech = async.valueOrNull?.byKey(techKey);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(tech?.name ?? 'Technology details')),
      body: SafeArea(
        child: ResponsiveBody(
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading analysis results...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
            ),
            data: (data) {
              final t = data.byKey(techKey);
              if (t == null) return const SwaraEmptyState(title: 'No results are available.', icon: Icons.inbox_outlined);
              return _content(t, data);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(TechnologyResult t, VideoAnalysisResults data) {
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      SwaraCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            TechStatusIcon(t.status, size: 26),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(t.name, style: AppTextStyles.heading2)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          _kv('Status', t.status.label, valueColor: t.status.color),
          if (t.version != null) _kv('Version', t.version!),
          if (t.processingTime != null) _kv('Processing time', fmtSeconds(t.processingTime)),
          if (t.video.hasDuration) _kv('Video duration', fmtSeconds(t.video.duration)),
        ]),
      ),
      if (!t.isCompleted) ...[
        const SizedBox(height: AppSpacing.md),
        _problemBanner(t),
      ],
      if (t.isCompleted && !t.tracking.isEmpty) ...[
        const SectionTitle('Tracking'),
        SwaraCard(
          child: Column(children: [
            if (t.tracking.processedFrames != null) _kv('Processed frames', '${t.tracking.processedFrames}'),
            if (t.tracking.missingFrames != null) _kv('Missing frames', '${t.tracking.missingFrames}'),
            if (t.tracking.trackingFailures != null) _kv('Tracking failures', '${t.tracking.trackingFailures}'),
            if (t.tracking.meanConfidence != null) _kv('Mean confidence', fmtNum(t.tracking.meanConfidence, digits: 3)),
          ]),
        ),
      ],
      const SectionTitle('Behaviors'),
      for (final key in data.behaviorKeys) _BehaviorTile(behavior: t.behavior(key), technology: t),
      if (t.thresholdsUsed.isNotEmpty || t.preprocessingNotes.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _technicalDetails(t),
      ],
      const SizedBox(height: AppSpacing.xl),
    ]);
  }

  Widget _problemBanner(TechnologyResult t) {
    final unavailable = t.status == TechStatus.unavailable;
    final color = t.status.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(t.status.icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(unavailable ? 'Technology unavailable' : 'Technology ${t.status.label.toLowerCase()}',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 2),
            Text('Reason: ${humanizeReason(t.reason)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.text)),
          ]),
        ),
      ]),
    );
  }

  Widget _technicalDetails(TechnologyResult t) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('Technical details', style: AppTextStyles.titleMedium),
        subtitle: Text('Thresholds used and preprocessing', style: AppTextStyles.caption),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in t.preprocessingNotes) Text('- $n', style: AppTextStyles.bodySmall),
          for (final e in t.thresholdsUsed.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${behaviorLabel(e.key)}: ${_compact(e.value)}', style: AppTextStyles.caption),
            ),
        ],
      ),
    );
  }

  static String _compact(dynamic v) {
    if (v is Map) return v.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return '$v';
  }
}

Widget _kv(String k, String v, {Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(k, style: AppTextStyles.bodySmall)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(v,
              textAlign: TextAlign.end,
              style: AppTextStyles.label.copyWith(color: valueColor ?? AppColors.text)),
        ),
      ]),
    );

/// One behavior. Unsupported / unavailable / failed behaviors never show
/// zero-valued numbers - only the honest status.
class _BehaviorTile extends StatelessWidget {
  final BehaviorResult behavior;
  final TechnologyResult technology;
  const _BehaviorTile({required this.behavior, required this.technology});

  @override
  Widget build(BuildContext context) {
    final b = behavior;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwaraCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: behaviorColor(b.key), shape: BoxShape.circle)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(behaviorLabel(b.key), style: AppTextStyles.titleMedium)),
            if (!b.isSupported) StatusPill(label: b.support.label, color: b.support.color, icon: b.support.icon),
          ]),
          const SizedBox(height: AppSpacing.xs),
          ..._body(),
        ]),
      ),
    );
  }

  List<Widget> _body() {
    final b = behavior;
    switch (b.support) {
      case BehaviorSupport.supported:
        return [
          _kv('Detected', b.detected ? 'Yes' : 'No'),
          _kv('Events (frequency)', '${b.eventCount}'),
          _kv('Total duration', fmtSeconds(b.totalDuration)),
          for (final e in b.featureSummary.entries) _kv(e.key.replaceAll('_', ' '), '${e.value}'),
          if (b.events.isNotEmpty)
            ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: EdgeInsets.zero,
                title: Text('Events (${b.events.length})', style: AppTextStyles.label),
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < b.events.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '#${i + 1}  ${b.events[i].startTime.toStringAsFixed(2)}-${b.events[i].endTime.toStringAsFixed(2)} s'
                        '  (${b.events[i].duration.toStringAsFixed(2)} s)'
                        '${b.events[i].peakValue != null ? '  peak ${b.events[i].peakValue!.toStringAsFixed(3)}' : ''}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.text),
                      ),
                    ),
                ],
              ),
        ];
      case BehaviorSupport.unsupported:
      case BehaviorSupport.unknown:
        return [Text('Not supported by this technology', style: AppTextStyles.bodySmall)];
      case BehaviorSupport.unavailable:
        return [
          Text('Technology unavailable', style: AppTextStyles.bodySmall),
          Text('Reason: ${humanizeReason(b.reason ?? technology.reason)}', style: AppTextStyles.caption),
        ];
      case BehaviorSupport.error:
        return [
          Text('Analysis failed for this behavior', style: AppTextStyles.bodySmall),
          Text('Reason: ${humanizeReason(b.reason ?? technology.reason)}', style: AppTextStyles.caption),
        ];
    }
  }
}
