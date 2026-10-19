import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

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
  final AudioRecorder _recorder = AudioRecorder();
  bool _isBusy = false;
  String? _errorMessage;
  late AnimationController _pulseController;

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
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission is required to record.');
      }
      final path = kIsWeb
          ? 'swara_recording.m4a'
          : '${(await getTemporaryDirectory()).path}/swara_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!mounted) return;
      setState(() => _state = RecordingState.recording);
      _startTimer();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Recording could not start: $error');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _seconds++;
      });
    });
  }

  Future<void> _pauseRecording() async {
    _timer?.cancel();
    await _recorder.pause();
    if (mounted) setState(() => _state = RecordingState.paused);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    if (!mounted) return;
    setState(() => _state = RecordingState.recording);
    _startTimer();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() => _isBusy = true);
    try {
      final recordingPath = await _recorder.stop();
      if (!mounted) return;
      setState(() => _state = RecordingState.completed);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.push('/c4/speech_processing', extra: recordingPath);
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = 'Recording could not be saved: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 8, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'ඔයාගේ ප්‍රියතම බල්ලා එක්ක දවසක්ම ගත කරන්න පුළුවන් නම්, ඔයා දෙන්නා මොනවා කරයිද?',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.text, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'කාලය අරගෙන ස්වභාවිකව කතා කරන්න.',
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
                      _state == RecordingState.initial
                          ? 'Tap to Start'
                          : (_state == RecordingState.completed
                              ? 'Done'
                              : (_state == RecordingState.paused
                                  ? 'Recording paused'
                                  : 'Recording your voice...')),
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_seconds),
                      style: AppTextStyles.heading1.copyWith(color: _state == RecordingState.recording ? AppColors.error : AppColors.primaryDeep),
                    ),
                    const SizedBox(height: 48),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_state == RecordingState.initial)
                      GestureDetector(
                        onTap: _isBusy ? null : _startRecording,
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
                          child: _isBusy
                              ? const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: CircularProgressIndicator(color: AppColors.white),
                                )
                              : const Icon(Icons.mic, color: AppColors.white, size: 48),
                        ),
                      )
                    else if (_state == RecordingState.recording || _state == RecordingState.paused)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _isBusy
                                ? null
                                : (_state == RecordingState.recording
                                    ? _pauseRecording
                                    : _resumeRecording),
                            icon: Icon(_state == RecordingState.recording ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 64, color: AppColors.warning),
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            onPressed: _isBusy ? null : _stopRecording,
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
