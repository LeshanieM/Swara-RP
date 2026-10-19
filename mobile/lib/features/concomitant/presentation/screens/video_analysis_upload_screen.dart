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
  Future<void> _start() async {
    if (!ref.read(authProvider).isAuthenticated) {
      context.push('/login?redirectTo=${Uri.encodeComponent('/c2/video/upload')}');
      return;
    }
    final id = await ref.read(videoAnalysisProvider.notifier).start(childId: widget.childId);
    if (id != null && mounted) context.pushReplacement('/c2/video/process/$id');
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
      appBar: AppBar(title: const Text('Video · වීඩියෝ')),
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: videoPagePadding(context),
            children: [
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
                      ? 'Upload complete · උඩුගත කිරීම අවසන්'
                      : 'Uploading video · වීඩියෝව උඩුගත කරමින්${start.progress > 0 ? ' · ${(start.progress * 100).toStringAsFixed(0)}%' : '...'}',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                width: double.infinity,
                child: SwaraButton(
                  label: 'Start · අරඹන්න',
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
        Text('Select video · වීඩියෝව තෝරන්න', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text('Choose from this device · ${kAllowedVideoExtensions.join(', ')}',
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
              'Preview unavailable',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(builder: (context, constraints) {
          final changeButton = SwaraButton(
            label: 'Change · වෙනස් කරන්න',
            icon: Icons.swap_horiz_rounded,
            outlined: true,
            onPressed: busy ? null : notifier.pick,
          );
          final removeButton = SwaraButton(
            label: 'Remove · ඉවත් කරන්න',
            icon: Icons.delete_outline,
            outlined: true,
            color: AppColors.error,
            onPressed: busy ? null : notifier.clear,
          );
          if (constraints.maxWidth < 460) {
            return Column(children: [
              SizedBox(width: double.infinity, child: changeButton),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: removeButton),
            ]);
          }
          return Row(children: [
            Expanded(child: changeButton),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: removeButton),
          ]);
        }),
      ]),
    );
  }

  Widget _history() {
    final async = ref.watch(videoAnalysisHistoryProvider(widget.childId));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(
        'Previous analyses · පෙර විශ්ලේෂණ',
        trailing: IconButton(
          tooltip: 'Refresh · යාවත්කාලීන කරන්න',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => ref.invalidate(videoAnalysisHistoryProvider(widget.childId)),
        ),
      ),
      async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SwaraLoadingWidget(message: 'Loading analyses · විශ්ලේෂණ පූරණය කරමින්'),
        ),
        error: (e, _) => Text(
          VideoAnalysisException.from(e).message,
          style: AppTextStyles.bodySmall,
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No analyses yet · තවම විශ්ලේෂණ නැත', style: AppTextStyles.bodySmall),
            );
          }
          return Column(children: [for (final s in items.take(10)) _historyTile(s)]);
        },
      ),
    ]);
  }

  Widget _historyTile(VideoAnalysisSummary s) {
    final (label, color) = switch (s.status) {
      'completed' => ('Done · අවසන්', AppColors.success),
      'failed' => ('Failed · අසාර්ථකයි', AppColors.error),
      'processing' => ('In progress · සිදුවෙමින්', AppColors.primary),
      _ => ('Queued · පෝලිමේ', AppColors.textLight),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwaraCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        onTap: () => context.push(s.isTerminal
            ? '/c2/video/results/${s.analysisId}'
            : '/c2/video/process/${s.analysisId}'),
        child: LayoutBuilder(builder: (context, constraints) {
          final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.filename ?? 'Video', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.label),
            Text(fmtDate(s.createdAt), style: AppTextStyles.caption),
          ]);
          if (constraints.maxWidth < 420) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.history, color: AppColors.primaryDeep),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: details),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: StatusPill(label: label, color: color),
              ),
            ]);
          }
          return Row(children: [
            const Icon(Icons.history, color: AppColors.primaryDeep),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: details),
            StatusPill(label: label, color: color),
          ]);
        }),
      ),
    );
  }
}
