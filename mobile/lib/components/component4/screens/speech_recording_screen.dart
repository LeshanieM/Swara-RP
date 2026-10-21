import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/core/audio/wav_recorder.dart';
import 'package:swara/core/network/api_exception.dart';

enum RecordingState { initial, recording, paused, completed }

class SpeechRecordingScreen extends StatefulWidget {
  const SpeechRecordingScreen({super.key});

  @override
  State<SpeechRecordingScreen> createState() => _SpeechRecordingScreenState();
}

class _SpeechRecordingScreenState extends State<SpeechRecordingScreen> {
  RecordingState _state = RecordingState.initial;
  final WavRecorder _recorder = WavRecorder();
  bool _nextBusy = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (C4Flow.isLive) {
      if (_state == RecordingState.paused) {
        await _recorder.resume();
      } else if (!await _recorder.start(prefix: 'c4')) {
        _showError('Microphone permission is needed to record.');
        return;
      }
    }
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _state = RecordingState.recording;
        });
      }
    });
  }

  void _pauseRecording() {
    if (C4Flow.isLive) _recorder.pause();
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _state = RecordingState.paused;
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    setState(() => _state = RecordingState.completed);
    if (C4Flow.isLive) {
      final audio = await _recorder.stop();
      try {
        if (audio == null) throw const ApiException('no_audio', 'Nothing was recorded. Please try again.');
        await C4Flow.upload(audio);
      } catch (e) {
        if (!mounted) return;
        _showError(ApiException.from(e).message);
        setState(() {
          _state = RecordingState.initial;
        });
        return;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) context.push('/c4/speech_processing');
  }

  /// The child answered: show the topic's next follow-up question (the recording keeps going).
  Future<void> _nextQuestion() async {
    setState(() => _nextBusy = true);
    try {
      await C4Flow.nextPrompt();
    } catch (e) {
      _showError(ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _nextBusy = false);
    }
  }

  /// The child didn't understand the follow-up: the skip is logged and the next follow-up shows.
  Future<void> _skipQuestion() async {
    setState(() => _nextBusy = true);
    try {
      await C4Flow.skipFollowUp();
    } catch (e) {
      _showError(ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _nextBusy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final question = C4Flow.view.questionSi;
    final followUpsLeft = (C4Flow.session?['prompts']?['followUpsRemaining'] as num?)?.toInt() ?? 0;
    final onFollowUp = C4Flow.session?['prompts']?['current']?['kind'] == 'follow_up';
    return Scaffold(
      backgroundColor: AppColors.groundRead,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 8, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      question,
                      style: AppTextStyles.heading3.copyWith(color: AppColors.text, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'කාලය අරගෙන ස්වභාවිකව කතා කරන්න. ඕනෑම පිළිතුරක් හොඳයි. · Take your time. Any answer is okay.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (_state == RecordingState.recording || _state == RecordingState.paused) ...[
                      Icon(_state == RecordingState.recording ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                          color: AppColors.primary, size: 56),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      _state == RecordingState.initial
                          ? 'සූදානම් වූ විට පටිගත කිරීම අරඹන්න'
                          : _state == RecordingState.completed
                              ? 'සකසමින්...'
                              : _state == RecordingState.paused
                                  ? 'තාවකාලිකව නවතා ඇත'
                                  : 'ඔයාගේ කතාව පටිගත කරමින්...',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (_state == RecordingState.initial)
                      Semantics(
                        button: true,
                        label: 'පටිගත කිරීම අරඹන්න',
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.coralTint, shape: BoxShape.circle),
                          child: Material(
                            color: AppColors.coralDeep,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _startRecording,
                              child: const SizedBox(
                                width: 88,
                                height: 88,
                                child: Icon(Icons.mic_none_rounded, color: AppColors.white, size: 40),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (_state == RecordingState.recording || _state == RecordingState.paused)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: _state == RecordingState.recording ? 'තාවකාලිකව නවත්වන්න' : 'නැවත අරඹන්න',
                            onPressed: _state == RecordingState.recording ? _pauseRecording : _startRecording,
                            icon: Icon(_state == RecordingState.recording ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 56, color: AppColors.primary),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            tooltip: 'නවතා ඉදිරියට යන්න',
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop_circle_outlined, size: 56, color: AppColors.coralDeep),
                          ),
                        ],
                      )
                    else if (_state == RecordingState.completed) ...[
                          const SizedBox(height: 32),
                          const LinearProgressIndicator(minHeight: 4),
                          const SizedBox(height: 16),
                          Text('පටිගත කිරීම සුරකිමින්...', style: AppTextStyles.body),
                    ],
                    if (C4Flow.isLive && followUpsLeft > 0 &&
                        (_state == RecordingState.recording || _state == RecordingState.paused)) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _nextBusy ? null : _nextQuestion,
                        icon: const Icon(Icons.forum_outlined),
                        label: const Text('ඊළඟ ප්‍රශ්නය (Next question)'),
                      ),
                    ],
                    if (C4Flow.isLive && onFollowUp &&
                        (_state == RecordingState.recording || _state == RecordingState.paused))
                      TextButton.icon(
                        onPressed: _nextBusy ? null : _skipQuestion,
                        icon: const Icon(Icons.help_outline),
                        label: const Text("මට තේරෙන්නේ නැහැ · Skip this question"),
                      ),
                    const SizedBox(height: 48),
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
