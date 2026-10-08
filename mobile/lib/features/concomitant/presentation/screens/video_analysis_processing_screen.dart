import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Step 3: polls the real backend status. Every row and counter comes from the
/// analysis job - nothing is simulated.
class VideoAnalysisProcessingScreen extends ConsumerStatefulWidget {
  final String analysisId;
  const VideoAnalysisProcessingScreen({super.key, required this.analysisId});

  @override
  ConsumerState<VideoAnalysisProcessingScreen> createState() => _ProcessingState();
}

class _ProcessingState extends ConsumerState<VideoAnalysisProcessingScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.analysisId;
    ref.listen<StatusPollState>(videoAnalysisStatusProvider(id), (prev, next) {
      final s = next.status;
      if (s != null && s.isCompleted && !_navigated && mounted) {
        _navigated = true;
        context.pushReplacement('/c2/video/results/$id');
      }
    });

    final poll = ref.watch(videoAnalysisStatusProvider(id));
    final s = poll.status;
    final err = poll.error;
    final fatal = err != null &&
        (err.kind == VideoAnalysisErrorKind.unauthorized || err.kind == VideoAnalysisErrorKind.notFound);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analyzing Video')),
      body: SafeArea(
        child: ResponsiveBody(
          child: Builder(builder: (_) {
            if (fatal) return _fatalError(err);
            if (s == null) {
              // Nothing received yet.
              if (err != null) return _connectionError(err);
              return const SwaraLoadingWidget(message: 'Contacting the analysis service...');
            }
            return _body(s, poll);
          }),
        ),
      ),
    );
  }

  Widget _body(AnalysisStatus s, StatusPollState poll) {
    final total = s.total > 0 ? s.total : s.requested.length;
    final finished = s.requested.isEmpty
        ? s.completed
        : s.requested.where((k) => const {TechStatus.completed, TechStatus.unavailable, TechStatus.failed}
            .contains(s.statusOf(k))).length;
    final failedJob = s.isFailed;

    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      if (poll.error != null) ...[
        _connectionBanner(poll.error!),
        const SizedBox(height: AppSpacing.md),
      ],
      SwaraCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            failedJob
                ? 'Analysis failed'
                : (s.status == 'queued' ? 'Analysis queued...' : 'Analysis in progress...'),
            style: AppTextStyles.heading3.copyWith(color: failedJob ? AppColors.error : null),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: total > 0 ? finished / total : null,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: failedJob ? AppColors.error : AppColors.primary,
            backgroundColor: AppColors.divider,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$finished / $total technologies finished', style: AppTextStyles.titleMedium),
          if (s.requested.isNotEmpty)
            Text(
              '${s.countOf(TechStatus.completed)} completed - '
              '${s.countOf(TechStatus.unavailable)} unavailable - '
              '${s.countOf(TechStatus.failed)} failed',
              style: AppTextStyles.caption,
            ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      for (final key in s.requested) _row(key, s.statusOf(key)),
      if (failedJob) ...[
        const SizedBox(height: AppSpacing.lg),
        _failedActions(),
      ] else ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          'The analysis keeps running on the server if you leave this screen. '
          'Reopen it from "Previous analyses".',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    ]);
  }

  Widget _row(String key, TechStatus st) {
    final name = kTechnologyDisplayNames[key] ?? key;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwaraCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(children: [
          TechStatusIcon(st),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(name, style: AppTextStyles.titleMedium)),
          Text(st.label, style: AppTextStyles.label.copyWith(color: st.color)),
        ]),
      ),
    );
  }

  Widget _failedActions() {
    final results = ref.watch(videoAnalysisResultsProvider(widget.analysisId));
    final detail = results.valueOrNull?.error;
    final hasPartial = results.valueOrNull?.hasResults ?? false;
    return Column(children: [
      if (detail != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(humanizeReason(detail), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ),
      SizedBox(
        width: double.infinity,
        child: SwaraButton(
          label: 'Try again',
          icon: Icons.refresh,
          // The selected video is still kept, so the user only has to press Start.
          onPressed: () => context.pushReplacement('/c2/video/upload'),
        ),
      ),
      if (hasPartial) ...[
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: SwaraButton(
            label: 'View available results',
            outlined: true,
            onPressed: () => context.pushReplacement('/c2/video/results/${widget.analysisId}'),
          ),
        ),
      ],
    ]);
  }

  Widget _connectionBanner(VideoAnalysisException e) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.warning),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('${e.message}\nStill retrying...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.text))),
      ]),
    );
  }

  Widget _connectionError(VideoAnalysisException e) {
    return SwaraErrorWidget(
      message: e.message,
      onRetry: () => ref.read(videoAnalysisStatusProvider(widget.analysisId).notifier).retryNow(),
    );
  }

  Widget _fatalError(VideoAnalysisException e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(e.message, style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          SwaraButton(
            label: 'Start a new analysis',
            icon: Icons.refresh,
            onPressed: () => context.pushReplacement('/c2/video/upload'),
          ),
        ]),
      ),
    );
  }
}
