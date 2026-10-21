import 'dart:async';
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

class _SpeechRecordingScreenState extends State<SpeechRecordingScreen> with SingleTickerProviderStateMixin {
  RecordingState _state = RecordingState.initial;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  final WavRecorder _recorder = WavRecorder();
  bool _nextBusy = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _pulseController.dispose();
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
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
    _timer?.cancel();
  }

  /// Below this, the answer is unlikely to hold the 5 sentences the sample needs.
  static const _minAnswerSec = 30;

  Future<void> _stopRecording() async {
    if (_seconds < _minAnswerSec) {
      final stop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('තව ටිකක් කියමුද?'),
          content: const Text('Try to say at least 5 sentences. Keep going, or answer the next question?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Stop anyway')),
          ],
        ),
      );
      if (stop != true || !mounted) return;
    }
    _timer?.cancel();
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
          _seconds = 0;
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final question = C4Flow.view.questionSi;
    final followUpsLeft = (C4Flow.session?['prompts']?['followUpsRemaining'] as num?)?.toInt() ?? 0;
    final onFollowUp = C4Flow.session?['prompts']?['current']?['kind'] == 'follow_up';
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      'කාලය අරගෙන ස්වභාවිකව කතා කරන්න. අඩුම තරමින් වාක්‍ය 5ක් කියන්න.\nTake your time and say at least 5 sentences.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (_state == RecordingState.recording) ...[
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: const Icon(Icons.graphic_eq, color: AppColors.primary, size: 64),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      _state == RecordingState.initial ? 'Tap to Start' : (_state == RecordingState.completed ? 'Done' : 'Recording...'),
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_seconds),
                      style: AppTextStyles.heading1.copyWith(color: _state == RecordingState.recording ? AppColors.error : AppColors.primaryDeep),
                    ),
                    const SizedBox(height: 48),
                    if (_state == RecordingState.initial)
                      GestureDetector(
                        onTap: _startRecording,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.error, blurRadius: 20, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.mic, color: AppColors.white, size: 48),
                        ),
                      )
                    else if (_state == RecordingState.recording || _state == RecordingState.paused)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _state == RecordingState.recording ? _pauseRecording : _startRecording,
                            icon: Icon(_state == RecordingState.recording ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 64, color: AppColors.warning),
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop_circle, size: 64, color: AppColors.error),
                          ),
                        ],
                      )
                    else if (_state == RecordingState.completed) ...[
                          const SizedBox(height: 32),
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text('Saving recording...', style: AppTextStyles.body),
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
