import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/widgets/parent_pin_dialog.dart';

class TranscriptionScreen extends ConsumerStatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  ConsumerState<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _saving = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Plays the local copy of the answer (the server deletes its copy after the analysis).
  Future<void> _play() async {
    final recording = C4Flow.recording;
    if (recording == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('මෙම උපකරණයේ පටිගත කිරීම සොයාගත නොහැක.')));
      return;
    }
    try {
      // The web keeps the answer as a blob URL; devices as a temp file.
      if (kIsWeb) {
        await _player.setUrl(recording.path);
      } else {
        await _player.setFilePath(recording.path);
      }
      await _player.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('පටිගත කිරීම වාදනය කළ නොහැකි විය.')));
      }
    }
  }

  /// The parent (or SLP) fixes what the speech model heard. The server keeps every version and
  /// re-measures the sample, so the analysis screens show the corrected numbers.
  Future<void> _correct(String current) async {
    final controller = TextEditingController(text: current);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('කථන පිටපත නිවැරදි කරන්න'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('දරුවා පැවසූ දේ නැවතීම්ද ඇතුළුව ඒ ආකාරයෙන්ම ලියන්න ("ම ම මම").', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          TextField(controller: controller, maxLines: 8, minLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('අවලංගු කරන්න')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('සුරකින්න')),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || text == current.trim() || !mounted) return;
    if (!await ensureParentMode(context, ref)) return;
    setState(() => _saving = true);
    try {
      await C4Flow.correctTranscript(text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiException.from(e).message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = C4Flow.view;
    return Scaffold(
      backgroundColor: AppColors.groundRead,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 10, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'ඔයා කියපු දේ',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ඔයා පැවසූ දේ',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                        border: Border.all(color: AppColors.primaryWash, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            v.transcript.isEmpty ? '—' : v.transcript,
                            style: AppTextStyles.body.copyWith(color: AppColors.text, height: 1.6),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.transcriptKind == 'asr' ? 'සිංහල හඬ හඳුනාගැනීම' : 'දෙමාපියන් නිවැරදි කළා', style: AppTextStyles.label),
                                  Text('සම්පූර්ණයි', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('පිළිතුරු කාලය', style: AppTextStyles.label),
                                  Text(fmtClock(v.durationSec), style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDeep)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: C4Flow.isLive ? _play : () {},
                      icon: const Icon(Icons.volume_up),
                      label: const Text('පටිගත කළ හඬට සවන් දෙන්න'),
                    ),
                    if (C4Flow.isLive && C4Flow.sampleId != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _correct(v.transcript),
                        icon: const Icon(Icons.edit_note),
                        label: Text(_saving ? 'සුරකිමින්...' : 'පිටපත නිවැරදි කරන්න (දෙමාපියන්)'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/analysis'),
                      child: const Text('කථනය විශ්ලේෂණය කරන්න'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
