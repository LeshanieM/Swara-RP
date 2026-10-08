import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
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
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _state = RecordingState.paused;
        });
      }
    });
    _timer?.cancel();
  }

  void _stopRecording() {
    _timer?.cancel();
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _state = RecordingState.completed;
        });
        // Automatically navigate to processing screen as requested
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.push('/c4/speech_processing');
          }
        });
      }
    });
  }

  void _resetRecording() {
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _state = RecordingState.initial;
          _seconds = 0;
        });
      }
    });
    _timer?.cancel();
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
