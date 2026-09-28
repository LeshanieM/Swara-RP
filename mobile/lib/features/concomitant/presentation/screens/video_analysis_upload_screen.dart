import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_preview_player.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';

/// Step 1 of the research workflow: select ONE video, preview it, start analysis.
class VideoAnalysisUploadScreen extends ConsumerStatefulWidget {
  final String childId;
  const VideoAnalysisUploadScreen({super.key, required this.childId});

  @override
  ConsumerState<VideoAnalysisUploadScreen> createState() => _VideoAnalysisUploadScreenState();
}

class _VideoAnalysisUploadScreenState extends ConsumerState<VideoAnalysisUploadScreen> {
  String? _groundTruthError;

  Future<void> _start() async {
    if (!ref.read(authProvider).isAuthenticated) {
      context.push('/login?redirectTo=${Uri.encodeComponent('/c2/video/upload')}');
      return;
    }
    final id = await ref.read(videoAnalysisProvider.notifier).start(childId: widget.childId);
    if (id != null && mounted) context.pushReplacement('/c2/video/process/$id');
  }

  Future<void> _pickGroundTruth() async {
    final err = await ref.read(groundTruthProvider.notifier).pick();
    if (mounted) setState(() => _groundTruthError = err);
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedVideoProvider);
    final start = ref.watch(videoAnalysisProvider);
    final video = selection.video;
    final busy = start.isUploading;
    final error = start.error ?? selection.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Video analysis')),
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const ResearchNote(
                'One video will be analyzed using all available computer-vision approaches.\n'
                'Results are visual movement events for research comparison - not a diagnosis.',
                icon: Icons.science_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (video == null) _emptyPicker(busy) else _selectedCard(video, busy),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppRadii.mdAll,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(error, style: AppTextStyles.bodySmall.copyWith(color: AppColors.text))),
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _researchOptions(busy),
              const SizedBox(height: AppSpacing.lg),
              if (busy) ...[
                LinearProgressIndicator(
                  value: start.progress > 0 && start.progress < 1 ? start.progress : null,
                  color: AppColors.primary,
                  backgroundColor: AppColors.divider,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  start.progress >= 1
                      ? 'Upload complete - creating the analysis...'
                      : 'Uploading video${start.progress > 0 ? ' - ${(start.progress * 100).toStringAsFixed(0)}%' : '...'}',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                width: double.infinity,
                child: SwaraButton(
                  label: 'Start Analysis',
                  icon: Icons.play_arrow_rounded,
                  isLoading: busy,
                  onPressed: _start, // validates: shows "select a video" when none is chosen
                ),
              ),
              _history(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyPicker(bool busy) {
    return SwaraCard(
      onTap: busy ? null : ref.read(selectedVideoProvider.notifier).pick,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: AppSpacing.lg),
      child: Column(children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primaryWash,
          child: Icon(Icons.video_library_outlined, size: 30, color: AppColors.primaryDeep),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Select video', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text('Tap to choose one video from this device\n(${kAllowedVideoExtensions.join(', ')})',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _selectedCard(SelectedVideo video, bool busy) {
    final notifier = ref.read(selectedVideoProvider.notifier);
    return SwaraCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.videocam_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(video.name,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleMedium),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
          StatusPill(label: fmtBytes(video.sizeBytes), color: AppColors.primaryDeep, icon: Icons.storage_outlined),
          if (video.duration != null)
            StatusPill(label: fmtClock(video.duration!), color: AppColors.primaryDeep, icon: Icons.timer_outlined),
        ]),
        const SizedBox(height: AppSpacing.md),
        if (video.path != null && !kIsWeb)
          VideoPreviewPlayer(
            key: ValueKey(video.path),
            filePath: video.path,
            onDuration: (d) => Future.microtask(() {
              if (mounted) notifier.setDuration(d);
            }),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadii.mdAll),
            child: Text(
              'Video preview is not available in the browser. The file will still be analyzed.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: SwaraButton(
              label: 'Replace',
              icon: Icons.swap_horiz_rounded,
              outlined: true,
              onPressed: busy ? null : notifier.pick,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SwaraButton(
              label: 'Remove',
              icon: Icons.delete_outline,
              outlined: true,
              color: AppColors.error,
              onPressed: busy ? null : notifier.clear,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _researchOptions(bool busy) {
    final overlay = ref.watch(generateOverlayProvider);
    final gt = ref.watch(groundTruthProvider);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.divider),
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.tune, color: AppColors.primaryDeep),
          title: Text('Research options', style: AppTextStyles.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: overlay,
              onChanged: busy ? null : (v) => ref.read(generateOverlayProvider.notifier).state = v,
              title: const Text('Generate annotated video'),
              subtitle: const Text('Only technologies that support it (currently MediaPipe). Slower.'),
            ),
            const Divider(),
            Text('Ground-truth annotations (optional)', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'JSON with an "annotations" list of {behavior, start_time, end_time}. '
              'Enables precision / recall / F1 on the metrics screen.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (gt == null)
              Align(
                alignment: Alignment.centerLeft,
                child: SwaraButton(
                  label: 'Attach JSON',
                  icon: Icons.attach_file,
                  outlined: true,
                  onPressed: busy ? null : _pickGroundTruth,
                ),
              )
            else
              Row(children: [
                const Icon(Icons.rule, color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('${gt.fileName} - ${gt.annotationCount} annotations')),
                IconButton(
                  tooltip: 'Remove annotations',
                  icon: const Icon(Icons.close),
                  onPressed: busy ? null : () => ref.read(groundTruthProvider.notifier).clear(),
                ),
              ]),
            if (_groundTruthError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(_groundTruthError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _history() {
    final async = ref.watch(videoAnalysisHistoryProvider(widget.childId));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(
        'Previous analyses',
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => ref.invalidate(videoAnalysisHistoryProvider(widget.childId)),
        ),
      ),
      async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SwaraLoadingWidget(message: 'Loading analyses...'),
        ),
        error: (e, _) => Text(
          VideoAnalysisException.from(e).message,
          style: AppTextStyles.bodySmall,
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No video analysis has been performed yet.', style: AppTextStyles.bodySmall),
            );
          }
          return Column(children: [for (final s in items.take(10)) _historyTile(s)]);
        },
      ),
    ]);
  }

  Widget _historyTile(VideoAnalysisSummary s) {
    final (label, color) = switch (s.status) {
      'completed' => ('Completed', AppColors.success),
      'failed' => ('Failed', AppColors.error),
      'processing' => ('Processing', AppColors.primary),
      _ => ('Queued', AppColors.textLight),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwaraCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        onTap: () => context.push(s.isTerminal
            ? '/c2/video/results/${s.analysisId}'
            : '/c2/video/process/${s.analysisId}'),
        child: Row(children: [
          const Icon(Icons.history, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.filename ?? 'Video', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.label),
              Text(fmtDate(s.createdAt), style: AppTextStyles.caption),
            ]),
          ),
          StatusPill(label: label, color: color),
        ]),
      ),
    );
  }
}
