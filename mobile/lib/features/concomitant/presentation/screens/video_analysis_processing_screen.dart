import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Step 3: polls the analysis on the API. Every row comes from the job's status -
/// nothing is simulated.
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
      if (s != null && (s.isCompleted || s.isNotAssessed) && !_navigated && mounted) {
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
      backgroundColor: AppColors.groundAdult,
      appBar: AppBar(
        title: Text('Movement analysis · චලන විශ්ලේෂණය', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: CalmSceneBackground(
        child: SafeArea(
        child: ResponsiveBody(
          child: Builder(builder: (_) {
            if (fatal) return _fatalError(err);
            if (s == null) {
              // Nothing received yet.
              if (err != null) return _connectionError(err);
              return const SwaraLoadingWidget(message: 'Contacting the analysis service... · විශ්ලේෂණ සේවාවට සම්බන්ධ වෙමින් පවතී');
            }
            return _body(s, poll);
          }),
        ),
        ),
      ),
    );
  }

  Widget _body(VideoAnalysis s, StatusPollState poll) {
    final stages = [for (final (key, _) in kAnalysisStages) s.stageStatus(key)];
    final finished = stages.where((st) => st == TechStatus.completed).length;
    final failedJob = s.isFailed;
    final current = kAnalysisStages.where((stage) => stage.$1 == s.status).map((stage) => stage.$2).firstOrNull;

    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      if (poll.error != null) ...[
        _connectionBanner(poll.error!),
        const SizedBox(height: AppSpacing.md),
      ],
      SwaraCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            failedJob
                ? 'Analysis could not finish · විශ්ලේෂණය අවසන් කිරීමට නොහැකි විය'
                : (s.status == 'queued'
                    ? 'Movement analysis queued · චලන විශ්ලේෂණය පෝලිමේ ඇත'
                    : 'Movement analysis in progress · චලන විශ්ලේෂණය සිදුවෙමින් පවතී'),
            style: AppTextStyles.heading3.copyWith(color: failedJob ? AppColors.error : null),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: finished / stages.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: failedJob ? AppColors.error : AppColors.primary,
            backgroundColor: AppColors.divider,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(failedJob
                  ? 'Movement analysis stopped · චලන විශ්ලේෂණය නතර විය'
                  : _stageLabel(current),
              style: AppTextStyles.titleMedium),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < kAnalysisStages.length; i++) _row(_stageLabel(kAnalysisStages[i].$2), stages[i]),
      if (failedJob) ...[
        const SizedBox(height: AppSpacing.lg),
        _failedActions(s),
      ] else ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          'මෙම තිරයෙන් පිටවුවත් විශ්ලේෂණය දිගටම සිදුවේ.',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    ]);
  }

  Widget _row(String name, TechStatus st) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwaraCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: LayoutBuilder(builder: (context, constraints) {
          final status = Text(st.label, style: AppTextStyles.label.copyWith(color: st.color));
          final title = Text(name, style: AppTextStyles.titleMedium, softWrap: true);
          if (constraints.maxWidth < 360) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TechStatusIcon(st),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                title,
                const SizedBox(height: AppSpacing.xs),
                status,
              ])),
            ]);
          }
          return Row(children: [
            TechStatusIcon(st),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: title),
            const SizedBox(width: AppSpacing.sm),
            status,
          ]);
        }),
      ),
    );
  }

  Widget _failedActions(VideoAnalysis s) {
    return Column(children: [
      if (s.errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text('${humanizeReason(s.errorMessage)} · කරුණාකර මෙම විස්තරය විශේෂඥයෙකු සමඟ සමාලෝචනය කරන්න.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ),
      SizedBox(
        width: double.infinity,
        child: SwaraButton(
          label: 'Try again · නැවත උත්සාහ කරන්න',
          icon: Icons.refresh,
          // The selected video is still kept, so the user only has to press Start.
          onPressed: () => context.pushReplacement('/c2/video/upload'),
        ),
      ),
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
        Expanded(child: Text('${e.message}\nStill retrying... · නැවත උත්සාහ කරමින් පවතී', style: AppTextStyles.bodySmall.copyWith(color: AppColors.text))),
      ]),
    );
  }

  Widget _connectionError(VideoAnalysisException e) {
    return SwaraErrorWidget(
      message: '${e.message} · සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
      onRetry: () => ref.read(videoAnalysisStatusProvider(widget.analysisId).notifier).retryNow(),
    );
  }

  String _stageLabel(String? stage) => switch (stage) {
        'Video received' => 'Video received · වීඩියෝව ලැබුණි',
        'Finding stutter moments in the audio' =>
          'Finding stutter moments in the audio · හඬ පටයේ ගොත ගැසෙන මොහොත සොයමින්',
        'Face and head movement at each stutter moment' =>
          'Face and head movement at each stutter moment · ගොත ගැසෙන මොහොතේ මුහුණේ සහ හිසේ චලනය බලමින්',
        _ => 'Preparing the analysis · විශ්ලේෂණය සූදානම් කරමින්',
      };

  Widget _fatalError(VideoAnalysisException e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text('${e.message} · විස්තර පරීක්ෂා කර නැවත උත්සාහ කරන්න.', style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          SwaraButton(
            label: 'Start a new analysis · නව විශ්ලේෂණයක් අරඹන්න',
            icon: Icons.refresh,
            onPressed: () => context.pushReplacement('/c2/video/upload'),
          ),
        ]),
      ),
    );
  }
}
