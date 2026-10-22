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
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/widgets/parent_pin_dialog.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import 'package:swara/features/speech/data/providers/speech_provider.dart';

/// Step 1 of the research workflow: select ONE video, preview it, start analysis.
/// The video is analysed for the active child (the signed-in child, or the child a therapist opened).
class VideoAnalysisUploadScreen extends ConsumerStatefulWidget {
  const VideoAnalysisUploadScreen({super.key});

  @override
  ConsumerState<VideoAnalysisUploadScreen> createState() => _VideoAnalysisUploadScreenState();
}

class _VideoAnalysisUploadScreenState extends ConsumerState<VideoAnalysisUploadScreen> {
  bool _consent = false;
  String? _localError;

  String get _childId => ref.read(activeChildProvider)?.childId ?? '';

  Future<void> _toggleConsent(bool? value) async {
    if (value != true) {
      setState(() => _consent = false);
      return;
    }
    // Consent is a parent decision, so it needs parent mode.
    if (await ensureParentMode(context, ref) && mounted) {
      setState(() {
        _consent = true;
        _localError = null;
      });
    }
  }

  Future<void> _start() async {
    if (!ref.read(authProvider).isAuthenticated) {
      context.push('/login?redirectTo=${Uri.encodeComponent('/c2/video/upload')}');
      return;
    }
    final child = ref.read(activeChildProvider);
    if (child == null) {
      setState(() => _localError = 'Choose a child on the therapist home first. · පළමුව චිකිත්සක මුල් පිටුවෙන් දරුවෙකු තෝරන්න.');
      return;
    }
    if (!_consent) {
      setState(() => _localError = 'A parent needs to give consent before the video is analysed. · වීඩියෝව විශ්ලේෂණය කිරීමට පෙර දෙමාපිය අනුමැතිය අවශ්‍යයි.');
      return;
    }
    if (!await ensureParentMode(context, ref)) return;
    // Ages 11–14 do the C1 reading task, so the API needs the passage read in the video.
    String? passageId;
    if (child.age > 10) {
      try {
        final task = await ref.read(speechServiceProvider).task(child.age);
        final passages = task.passages;
        if (passages.isNotEmpty) {
          passageId = passages.firstWhere((p) => p.language == 'si', orElse: () => passages.first).id;
        }
      } catch (e) {
        setState(() => _localError = '${ApiException.from(e).message} · කරුණාකර නැවත උත්සාහ කරන්න.');
        return;
      }
    }
    setState(() => _localError = null);
    final id = await ref
        .read(videoAnalysisProvider.notifier)
        .start(childId: child.childId, age: child.age, passageId: passageId);
    if (id != null && mounted) context.pushReplacement('/c2/video/process/$id');
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedVideoProvider);
    final start = ref.watch(videoAnalysisProvider);
    final video = selection.video;
    final busy = start.isUploading;
    final error = _localError ?? start.error ?? selection.error;

    return Scaffold(
      backgroundColor: AppColors.groundAdult,
      appBar: AppBar(
        title: Text('Video analysis · වීඩියෝ විශ්ලේෂණය', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: CalmSceneBackground(
        child: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? AppSpacing.md : AppSpacing.lg),
            children: [
              Text(
                'දරුවාගේ වීඩියෝව තෝරන්න · Select a child video',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
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
                    Expanded(child: Text('$error · කරුණාකර විස්තර පරීක්ෂා කර නැවත උත්සාහ කරන්න.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.text))),
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _consentCard(busy),
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
                      ? 'Upload complete - creating the analysis... · උඩුගත කිරීම සම්පූර්ණයි; විශ්ලේෂණය සකසමින්'
                      : 'Uploading video${start.progress > 0 ? ' - ${(start.progress * 100).toStringAsFixed(0)}%' : '...'} · වීඩියෝව උඩුගත කරමින්',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                width: double.infinity,
                child: SwaraButton(
                  label: 'Analyze · විශ්ලේෂණය',
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
      ),
    );
  }

  Widget _consentCard(bool busy) {
    return SwaraCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: CheckboxListTile(
        value: _consent,
        onChanged: busy ? null : _toggleConsent,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: Text('Parent consent · දෙමාපිය අනුමැතිය', style: AppTextStyles.titleMedium),
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
        Text('Tap to choose one video from this device · මෙම උපාංගයෙන් වීඩියෝවක් තෝරන්න\n(${kAllowedVideoExtensions.join(', ')})',
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
              'බ්‍රවුසරයේ පෙරදසුන නොපෙනේ. ගොනුව විශ්ලේෂණය කළ හැකියි.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(builder: (context, constraints) {
          final stacked = constraints.maxWidth < 360;
          final replace = SwaraButton(
            label: 'Replace · වෙනස් කරන්න',
            icon: Icons.swap_horiz_rounded,
            outlined: true,
            onPressed: busy ? null : notifier.pick,
          );
          final remove = SwaraButton(
            label: 'Remove · ඉවත් කරන්න',
            icon: Icons.delete_outline,
            outlined: true,
            color: AppColors.error,
            onPressed: busy ? null : notifier.clear,
          );
          if (stacked) {
            return Column(children: [
              SizedBox(width: double.infinity, child: replace),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: remove),
            ]);
          }
          return Row(children: [
          Expanded(
            child: replace,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: remove,
          ),
          ]);
        }),
      ]),
    );
  }

  Widget _history() {
    final async = ref.watch(videoAnalysisHistoryProvider(_childId));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(
        'Previous analyses · පෙර විශ්ලේෂණ',
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => ref.invalidate(videoAnalysisHistoryProvider(_childId)),
        ),
      ),
      async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SwaraLoadingWidget(message: 'Loading analyses... · විශ්ලේෂණ පූරණය වෙමින් පවතී'),
        ),
        error: (e, _) => Text(
          '${VideoAnalysisException.from(e).message} · සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
          style: AppTextStyles.bodySmall,
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No video analysis has been performed yet. · තවම වීඩියෝ විශ්ලේෂණයක් කර නැත.', style: AppTextStyles.bodySmall),
            );
          }
          return Column(children: [for (final s in items.take(10)) _historyTile(s)]);
        },
      ),
    ]);
  }

  Widget _historyTile(VideoAnalysis s) {
    final (label, color) = switch (s.status) {
      'completed' => ('Completed · සම්පූර්ණයි', AppColors.success),
      'failed' => ('Failed · අසාර්ථකයි', AppColors.error),
      'not_assessed' => ('Not assessed · තක්සේරු කර නැත', AppColors.textLight),
      'processing' || 'awaiting_stutter_events' => ('Processing · සැකසෙමින් පවතී', AppColors.primary),
      _ => ('Queued · පෝලිමේ', AppColors.textLight),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwaraCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        onTap: () => context.push(s.isTerminal
            ? '/c2/video/results/${s.id}'
            : '/c2/video/process/${s.id}'),
        child: Row(children: [
          const Icon(Icons.history, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.filename ?? 'Video · වීඩියෝව', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.label),
              Text(fmtDate(s.createdAt), style: AppTextStyles.caption),
            ]),
          ),
          StatusPill(label: label, color: color),
        ]),
      ),
    );
  }
}
