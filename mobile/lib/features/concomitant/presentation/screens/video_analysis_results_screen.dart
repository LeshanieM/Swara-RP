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
        title: const Text('Movement analysis results · චලන විශ්ලේෂණ ප්‍රතිඵල'),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.face_retouching_natural, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.titleMedium.copyWith(color: color))),
        ]),
        const SizedBox(height: AppSpacing.md),
        _metricLine('Moments with a behaviour · හැසිරීමක් දක්නට ලැබුණු අවස්ථා', '${r.momentsWithBehaviour} of ${r.momentsAssessed} assessed · තක්සේරු කළා'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Facial grimace (FG) · මුහුණේ තදවීම', '${r.fgCount}'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Head movement (HM) · හිස චලනය', '${r.hmCount}'),
        if (r.concomitantScore != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _metricLine('Concomitant score · සමගාමී හැසිරීම් ලකුණ', r.concomitantScore!.toStringAsFixed(2)),
        ],
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
        if (exceeded > 0) StatusPill(label: '$exceeded unusual · අසාමාන්‍ය', color: AppColors.warning),
        ]),
        const SizedBox(height: AppSpacing.md),
        _metricLine('Mean deviation · සාමාන්‍ය අපගමනය', mean == null ? '—' : '${mean.toStringAsFixed(1)} SD'),
        const SizedBox(height: AppSpacing.xs),
        _metricLine('Peak deviation · ඉහළම අපගමනය', peak == null ? '—' : '${peak.toStringAsFixed(1)} SD'),
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
        title: Text('Stutter moments · ගොත ගැසෙන අවස්ථා', style: AppTextStyles.titleMedium),
        subtitle: Text('${r.momentsAssessed} of ${r.momentsTotal} could be assessed · තක්සේරු කළ හැකි විය', style: AppTextStyles.caption),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [
          for (final m in r.moments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Row(children: [
                Expanded(
                  child: Text(
                    'Moment ${m.index + 1} · අවස්ථාව ${m.index + 1} · ${m.start.toStringAsFixed(1)}–${m.end.toStringAsFixed(1)} s'
                    '${m.types.isEmpty ? '' : ' · ${m.types.map((t) => t.replaceAll('_', ' ')).join(', ')}'}',
                    style: AppTextStyles.label,
                  ),
                ),
                if (!m.assessed) const StatusPill(label: 'Face not visible · මුහුණ නොපෙනේ', color: AppColors.textLight),
                if (m.fg.present) const StatusPill(label: 'FG · මුහුණ', color: AppColors.warning),
                if (m.hm.present) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const StatusPill(label: 'HM · හිස', color: AppColors.warning),
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
