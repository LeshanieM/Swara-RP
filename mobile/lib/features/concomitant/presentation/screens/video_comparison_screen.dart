import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

enum _Metric { events, duration }

/// Cross-technology comparison. Every table is generated from the backend
/// results; nothing is hard-coded and no technology is ranked or labelled "best".
class VideoComparisonScreen extends ConsumerStatefulWidget {
  final String analysisId;
  const VideoComparisonScreen({super.key, required this.analysisId});

  @override
  ConsumerState<VideoComparisonScreen> createState() => _VideoComparisonScreenState();
}

class _VideoComparisonScreenState extends ConsumerState<VideoComparisonScreen> {
  _Metric _metric = _Metric.events;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(videoAnalysisResultsProvider(widget.analysisId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Comparison')),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 1000,
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading analysis results...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(widget.analysisId)),
            ),
            data: (data) => data.hasResults
                ? _content(data)
                : const SwaraEmptyState(title: 'No results are available.', icon: Icons.inbox_outlined),
          ),
        ),
      ),
    );
  }

  Widget _content(VideoAnalysisResults data) {
    final techs = data.technologies;
    final behaviors = data.behaviorKeys;
    final columns = [for (final t in techs) t.name];

    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      const ResearchNote(
        'Experimental comparison only. No technology is ranked or labelled best; differences in '
        'counts reflect different detection approaches and are not a measure of accuracy.',
      ),
      const SectionTitle('Behavior support'),
      _legend(),
      const SizedBox(height: AppSpacing.sm),
      _Table(
        firstColumn: 'Behavior',
        columns: columns,
        rows: [
          for (final b in behaviors)
            _Row(behaviorLabel(b), [
              for (final t in techs) _supportCell(t.supportFor(b)),
            ]),
        ],
      ),
      SectionTitle(
        'Quantitative comparison',
        trailing: SegmentedButton<_Metric>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(value: _Metric.events, label: Text('Events')),
            ButtonSegment(value: _Metric.duration, label: Text('Duration')),
          ],
          selected: {_metric},
          onSelectionChanged: (s) => setState(() => _metric = s.first),
        ),
      ),
      Text(
        _metric == _Metric.events
            ? 'Event count (= frequency in this video). "-" means no value: not supported, unavailable or failed.'
            : 'Total duration of detected events, in seconds. "-" means no value.',
        style: AppTextStyles.caption,
      ),
      const SizedBox(height: AppSpacing.sm),
      _Table(
        firstColumn: 'Behavior',
        columns: columns,
        rows: [
          for (final b in behaviors)
            _Row(behaviorLabel(b), [
              for (final t in techs) _valueCell(t.behavior(b)),
            ]),
        ],
      ),
      const SectionTitle('Processing and tracking'),
      _Table(
        firstColumn: 'Metric',
        columns: columns,
        rows: [
          _Row('Status', [
            for (final t in techs)
              Text(t.status.label, style: AppTextStyles.label.copyWith(color: t.status.color)),
          ]),
          _Row('Processing time', [for (final t in techs) _plain(t.isCompleted ? fmtSeconds(t.processingTime) : null)]),
          _Row('Processed frames', [for (final t in techs) _plain(t.isCompleted ? _i(t.tracking.processedFrames) : null)]),
          _Row('Missing frames', [for (final t in techs) _plain(t.isCompleted ? _i(t.tracking.missingFrames) : null)]),
          _Row('Tracking failures', [for (final t in techs) _plain(t.isCompleted ? _i(t.tracking.trackingFailures) : null)]),
          _Row('Mean confidence', [
            for (final t in techs)
              _plain(t.isCompleted && t.tracking.meanConfidence != null
                  ? fmtNum(t.tracking.meanConfidence, digits: 3)
                  : null),
          ]),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text('Confidence is shown only where a technology reports it.', style: AppTextStyles.caption),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }

  String? _i(int? v) => v?.toString();

  Widget _plain(String? v) =>
      Text(v ?? '-', style: AppTextStyles.bodySmall.copyWith(color: v == null ? AppColors.textLight : AppColors.text));

  Widget _supportCell(BehaviorSupport s) =>
      Tooltip(message: s.label, child: Icon(s.icon, color: s.color, size: 22));

  Widget _valueCell(BehaviorResult b) {
    if (!b.isSupported) return _plain(null);
    return Text(
      _metric == _Metric.events ? '${b.eventCount}' : b.totalDuration.toStringAsFixed(2),
      style: AppTextStyles.label,
    );
  }

  Widget _legend() {
    Widget item(BehaviorSupport s) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(s.icon, color: s.color, size: 18),
          const SizedBox(width: 4),
          Text(s.label, style: AppTextStyles.caption),
        ]);
    return Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.xs, children: [
      item(BehaviorSupport.supported),
      item(BehaviorSupport.unsupported),
      item(BehaviorSupport.unavailable),
      item(BehaviorSupport.error),
    ]);
  }
}

class _Row {
  final String label;
  final List<Widget> cells;
  const _Row(this.label, this.cells);
}

/// Horizontally scrollable table so wide comparisons fit small screens.
class _Table extends StatelessWidget {
  final String firstColumn;
  final List<String> columns;
  final List<_Row> rows;
  const _Table({required this.firstColumn, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdAll,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            headingRowHeight: 44,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            headingTextStyle: AppTextStyles.label,
            columns: [
              DataColumn(label: Text(firstColumn)),
              for (final c in columns) DataColumn(label: Text(c)),
            ],
            rows: [
              for (final r in rows)
                DataRow(cells: [
                  DataCell(Text(r.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.text))),
                  for (final c in r.cells) DataCell(Center(child: c)),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
