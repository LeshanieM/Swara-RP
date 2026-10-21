import 'dart:math' as math;

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
        title: Text('Movement analysis results · චලන විශ්ලේෂණ ප්‍රතිඵල', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
          tooltip: 'Refresh · නැවුම් කරන්න',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(videoAnalysisResultsProvider(analysisId)),
          ),
        ],
      ),
      body: CalmSceneBackground(
        child: SafeArea(
        child: ResponsiveBody(
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading the analysis... · විශ්ලේෂණය පූරණය වෙමින් පවතී'),
            error: (e, _) => SwaraErrorWidget(
              message: '${VideoAnalysisException.from(e).message} · සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
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
        title: 'Not assessed · තක්සේරු කර නැත',
        subtitle: 'වීඩියෝවක් නොතිබූ නිසා අමතර හැසිරීම් තක්සේරු කළේ නැත.',
        icon: Icons.videocam_off_outlined,
      );
    }
    final result = data.result;
    if (!data.isCompleted || result == null) {
      return SwaraErrorWidget(
        message: data.isFailed
            ? 'The analysis did not complete · විශ්ලේෂණය සම්පූර්ණ වූයේ නැත. ${humanizeReason(data.errorMessage)} · විස්තර පරීක්ෂා කර නැවත උත්සාහ කරන්න.'
            : 'The analysis is still running · විශ්ලේෂණය තවමත් සිදුවෙමින් පවතී.',
        onRetry: () => context.pushReplacement(data.isFailed ? '/c2/video/upload' : '/c2/video/process/${data.id}'),
      );
    }
    if (result.moments.isEmpty) {
      return SwaraEmptyState(
        title: 'No stutter moments were found · ගොත ගැසෙන අවස්ථා හමු නොවීය',
        subtitle: 'අමතර හැසිරීම් පරීක්ෂා කරන්නේ ගොත ගැසෙන අවස්ථාවලදී පමණයි.',
        icon: Icons.face_retouching_off_outlined,
      );
    }

    final meta = result.video;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? AppSpacing.md : AppSpacing.lg),
      children: [
        SwaraCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.videocam_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(data.filename ?? 'Analyzed video · විශ්ලේෂණය කළ වීඩියෝව',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleMedium),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              StatusPill(label: '${result.momentsTotal} stutter moments · ගොත ගැසීම් අවස්ථා', color: AppColors.primaryDeep,
                  icon: Icons.view_week_outlined),
              if (meta.duration != null)
                StatusPill(label: fmtSeconds(meta.duration, digits: 0), color: AppColors.primaryDeep),
              if (meta.analysedFps != null)
                StatusPill(label: '${meta.analysedFps!.toStringAsFixed(0)} sampled fps · නියැදි රාමු/තත්පර', color: AppColors.primaryDeep),
              if (meta.resolution != null)
                StatusPill(label: meta.resolution!, color: AppColors.primaryDeep),
              if (result.detectorFallback)
                const StatusPill(label: 'Fallback detector · විකල්ප හඳුනාගැනීම', color: AppColors.warning),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _summaryCard(result),
        const SizedBox(height: AppSpacing.md),
        const SectionTitle('Movement at stutter moments · ගොත ගැසෙන අවස්ථාවල චලනය'),
        _channelGrid(result),
        const SizedBox(height: AppSpacing.md),
        _momentList(result),
        const SizedBox(height: AppSpacing.md),
        SwaraCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tracking · නිරීක්ෂණය', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${meta.framesAnalysed ?? 0} frames analyzed · රාමු විශ්ලේෂණය කළා'
              '${meta.missingFrames == null ? '' : ' · ${meta.missingFrames} frames without a face · මුහුණක් නොපෙනුණු රාමු'}',
              style: AppTextStyles.bodySmall,
            ),
            if (result.processingSeconds != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Processing time · සැකසීමට ගත වූ කාලය: ${fmtSeconds(result.processingSeconds)}',
                    style: AppTextStyles.caption),
              ),
            for (final w in result.warnings)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Note · සටහන: $w', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: () => context.pushReplacement('/c2/video/upload'),
          icon: const Icon(Icons.add),
          label: const Text('Analyze another video · තවත් වීඩියෝවක් විශ්ලේෂණය කරන්න'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _summaryCard(C2Result r) {
    final (label, color) = switch (r.hasSecondaryBehaviors) {
      true => ('Secondary behaviours seen · අමතර හැසිරීම් දක්නට ලැබුණි', AppColors.warning),
      false => ('No secondary behaviours seen · අමතර හැසිරීම් දක්නට නොලැබුණි', AppColors.success),
      null => ('Could not be assessed · තක්සේරු කිරීමට නොහැකි විය', AppColors.textLight),
    };
    return SwaraCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.face_retouching_natural, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.label.copyWith(color: color))),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${r.momentsWithBehaviour} / ${r.momentsAssessed} assessed moments · තක්සේරු කළ අවස්ථා',
          style: AppTextStyles.label,
        ),
        if (r.concomitantScore != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Score · ලකුණ  ${r.concomitantScore!.toStringAsFixed(2)}', style: AppTextStyles.caption),
        ],
        const SizedBox(height: AppSpacing.md),
        _pieDistribution(r),
      ]),
    );
  }

  Widget _pieDistribution(C2Result result) {
    var fgOnly = 0;
    var hmOnly = 0;
    var both = 0;
    var neither = 0;
    for (final moment in result.assessedMoments) {
      if (moment.fg.present && moment.hm.present) {
        both++;
      } else if (moment.fg.present) {
        fgOnly++;
      } else if (moment.hm.present) {
        hmOnly++;
      } else {
        neither++;
      }
    }
    final slices = <_PieSliceData>[
      _PieSliceData('FG only · මුහුණ පමණක්', fgOnly, AppColors.coralDeep),
      _PieSliceData('HM only · හිස පමණක්', hmOnly, AppColors.primaryDeep),
      _PieSliceData('Both · දෙකම', both, AppColors.sun),
      _PieSliceData('Neither · කිසිවක් නැත', neither, AppColors.success),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Assessed moment results · තක්සේරු කළ අවස්ථා', style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.xs),
      Text('Pinch to zoom · විශාල කිරීමට ඇඟිලි දෙකෙන් විහිදුවන්න', style: AppTextStyles.caption),
      const SizedBox(height: AppSpacing.sm),
      LayoutBuilder(builder: (context, constraints) {
        final chartSize = constraints.maxWidth < 350 ? 180.0 : 210.0;
        final chart = SizedBox(
          width: chartSize,
          height: chartSize,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(48),
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: CustomPaint(
                painter: _PieChartPainter(slices.map((slice) => slice.value.toDouble()).toList(),
                    slices.map((slice) => slice.color).toList()),
              ),
            ),
          ),
        );
        final legend = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final slice in slices) _pieLegend(slice, result.momentsAssessed),
            const SizedBox(height: AppSpacing.xs),
            Text('Total: ${result.momentsAssessed}', style: AppTextStyles.caption),
          ],
        );
        if (constraints.maxWidth >= 440) {
          return Row(children: [chart, const SizedBox(width: AppSpacing.md), Expanded(child: legend)]);
        }
        return Column(children: [chart, legend]);
      }),
    ]);
  }

  Widget _pieLegend(_PieSliceData slice, int total) {
    final percent = total == 0 ? 0 : (slice.value * 100 / total).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(slice.label, style: AppTextStyles.caption)),
        Text('${slice.value} ($percent%)', style: AppTextStyles.label),
      ]),
    );
  }

  Widget _channelGrid(C2Result r) {
    final channels = const [
      ('eye', 'Eye movement · ඇස් චලනය', Icons.remove_red_eye_outlined),
      ('lip', 'Lip movement · තොල් චලනය', Icons.sentiment_satisfied_alt_outlined),
      ('jaw', 'Jaw movement · හකු චලනය', Icons.face_outlined),
      ('cheek', 'Cheek movement · කම්මුල් චලනය', Icons.mood_outlined),
      ('head', 'Head movement · හිස චලනය', Icons.accessibility_new_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 360 ? 2 : 1;
      final width = columns == 2 ? (constraints.maxWidth - AppSpacing.sm) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primaryDeep, size: 19),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: AppTextStyles.label)),
          if (exceeded > 0) Text('$exceeded', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _metricLine('Mean deviation · සාමාන්‍ය අපගමනය', mean == null ? '—' : '${mean.toStringAsFixed(1)} SD'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Peak deviation · ඉහළම අපගමනය', peak == null ? '—' : '${peak.toStringAsFixed(1)} SD'),
      ]),
    );
  }

  Widget _metricLine(String label, String value) => LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: AppTextStyles.label),
          ]);
        }
        return Row(children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(value, style: AppTextStyles.label, textAlign: TextAlign.end)),
        ]);
      });

  Widget _momentList(C2Result r) {
    return SwaraCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.view_timeline_outlined, color: AppColors.primaryDeep),
        title: Text('Stutter moments · ගොත ගැසෙන අවස්ථා', style: AppTextStyles.titleMedium),
        subtitle: Text('${r.momentsAssessed} of ${r.momentsTotal} could be assessed · තක්සේරු කළ හැකි විය', style: AppTextStyles.caption),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [
          for (final m in r.moments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    'Moment ${m.index + 1} · අවස්ථාව ${m.index + 1} · ${m.start.toStringAsFixed(1)}–${m.end.toStringAsFixed(1)} s'
                    '${m.types.isEmpty ? '' : ' · ${m.types.map((t) => t.replaceAll('_', ' ')).join(', ')}'}',
                    style: AppTextStyles.label,
                ),
                if (!m.assessed || m.fg.present || m.hm.present) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                    if (!m.assessed) const StatusPill(label: 'Face not visible · මුහුණ නොපෙනේ', color: AppColors.textLight),
                    if (m.fg.present) const StatusPill(label: 'FG · මුහුණ', color: AppColors.warning),
                    if (m.hm.present) const StatusPill(label: 'HM · හිස', color: AppColors.warning),
                  ]),
                ],
              ]),
              subtitle: Text(
                m.explanation.isNotEmpty
                    ? '${m.explanation.join('\n')}\nResearch estimate · පර්යේෂණ ඇස්තමේන්තුවක්'
                    : (m.assessed
                        ? 'Within this child\'s normal movement. · මෙම දරුවාගේ සාමාන්‍ය චලන පරාසය තුළයි.'
                        : 'Too little of the face was visible. · මුහුණ ප්‍රමාණවත් ලෙස නොපෙනුණි.'),
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

class _PieSliceData {
  final String label;
  final int value;
  final Color color;

  const _PieSliceData(this.label, this.value, this.color);
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const _PieChartPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: diameter / 2);
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      canvas.drawCircle(rect.center, rect.width / 2, Paint()..color = AppColors.divider);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      start += sweep;
    }
    canvas.drawCircle(
      rect.center,
      diameter / 2,
      Paint()
        ..color = AppColors.surfaceRaised
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}
