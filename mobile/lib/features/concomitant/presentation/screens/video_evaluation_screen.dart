import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

/// Research metrics against SLP ground truth. Shows nothing invented: when no
/// annotations were supplied the screen says so instead of showing values.
class VideoEvaluationScreen extends ConsumerWidget {
  final String analysisId;
  const VideoEvaluationScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoAnalysisResultsProvider(analysisId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Research metrics')),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 1000,
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading analysis results...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
            ),
            data: _content,
          ),
        ),
      ),
    );
  }

  Widget _content(VideoAnalysisResults data) {
    final eval = data.evaluation;
    if (!eval.groundTruthProvided) {
      return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
        SwaraCard(
          child: Column(children: [
            const Icon(Icons.fact_check_outlined, size: 40, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.md),
            Text('Ground truth annotations have not been provided.', style: AppTextStyles.heading3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Evaluation metrics are therefore unavailable.', style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(
              'To evaluate a technology, attach annotations (JSON) under "Research options" '
              'when starting an analysis.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]);
    }

    final techs = data.technologies.where((t) => eval.perTechnology.containsKey(t.name)).toList();
    if (techs.isEmpty) {
      return const SwaraEmptyState(title: 'No evaluation results are available.', icon: Icons.inbox_outlined);
    }
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      const ResearchNote(
        'A detected and an annotated event match when their time intervals overlap sufficiently (IoU). '
        'Timing and duration errors are mean absolute errors in seconds. Accuracy is not reported: '
        'true negatives are not defined for event detection.',
      ),
      const SizedBox(height: AppSpacing.md),
      for (final t in techs) _techCard(t, eval.perTechnology[t.name]!, data.behaviorKeys),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }

  Widget _techCard(TechnologyResult t, Map<String, BehaviorEvaluation> per, List<String> keys) {
    final evaluated = [for (final k in keys) if (per[k]?.evaluated == true) k];
    final skipped = [for (final k in keys) if (per[k] != null && per[k]!.evaluated != true) k];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SwaraCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: true,
          title: Text(t.name, style: AppTextStyles.heading3),
          subtitle: Text('${evaluated.length} behavior(s) evaluated', style: AppTextStyles.caption),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (evaluated.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingTextStyle: AppTextStyles.label,
                  columns: const [
                    DataColumn(label: Text('Behavior')),
                    DataColumn(label: Text('Precision')),
                    DataColumn(label: Text('Recall')),
                    DataColumn(label: Text('F1')),
                    DataColumn(label: Text('TP')),
                    DataColumn(label: Text('FP')),
                    DataColumn(label: Text('FN')),
                    DataColumn(label: Text('Freq. error')),
                    DataColumn(label: Text('Timing MAE (s)')),
                    DataColumn(label: Text('Duration MAE (s)')),
                  ],
                  rows: [
                    for (final k in evaluated)
                      DataRow(cells: [
                        DataCell(Text(behaviorLabel(k))),
                        DataCell(Text(fmtNum(per[k]!.precision, digits: 3))),
                        DataCell(Text(fmtNum(per[k]!.recall, digits: 3))),
                        DataCell(Text(fmtNum(per[k]!.f1, digits: 3))),
                        DataCell(Text(fmtNum(per[k]!.truePositives))),
                        DataCell(Text(fmtNum(per[k]!.falsePositives))),
                        DataCell(Text(fmtNum(per[k]!.falseNegatives))),
                        DataCell(Text(per[k]!.frequencyError == null
                            ? '-'
                            : (per[k]!.frequencyError! > 0 ? '+' : '') + '${per[k]!.frequencyError}')),
                        DataCell(Text(fmtNum(per[k]!.meanTimingError, digits: 3))),
                        DataCell(Text(fmtNum(per[k]!.meanDurationError, digits: 3))),
                      ]),
                  ],
                ),
              ),
            if (skipped.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Not evaluated', style: AppTextStyles.label),
              for (final k in skipped)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${behaviorLabel(k)}: ${per[k]!.reason ?? 'no reason reported'}', style: AppTextStyles.caption),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
