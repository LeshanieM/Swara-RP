import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantRecordingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> assessmentData;
  const ConcomitantRecordingScreen({super.key, required this.assessmentData});

  @override
  ConsumerState<ConcomitantRecordingScreen> createState() => _ConcomitantRecordingScreenState();
}

class _ConcomitantRecordingScreenState extends ConsumerState<ConcomitantRecordingScreen> {
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  void _finishRecording() {
    _timer?.cancel();
    context.pushReplacement('/c2/process', extra: {
      ...widget.assessmentData,
      'duration': _seconds,
    });
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c2Gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🎥 කැමරා ක්‍රියාකාරකම', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Camera Recording Activity', style: TextStyle(color: AppColors.softYellow, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                _isRecording ? 'නියමයි! දිගටම කරගෙන යන්න... 🌟' : 'මයික් එක ඔබලා පටන් ගන්න! 🎤',
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _isRecording ? AppColors.coralRed : AppColors.softYellow, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15)
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.face_retouching_natural, size: 90, color: Colors.white70),
                        const SizedBox(height: 16),
                        Text(
                          _isRecording ? '📸 කැමරාව ක්‍රියාත්මකයි\nCamera Active' : 'කැමරාව සූදානම්\nCamera Ready',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _formatTime(_seconds),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_isRecording && _seconds > 0)
                      GestureDetector(
                        onTap: () => setState(() => _seconds = 0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: AppColors.softYellow, shape: BoxShape.circle),
                          child: const Icon(Icons.refresh, size: 32, color: AppColors.jewelNavy),
                        ),
                      )
                    else
                      const SizedBox(width: 64),
                      
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? AppColors.coralRed : AppColors.ctaOrange,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: (_isRecording ? AppColors.coralRed : AppColors.ctaOrange).withOpacity(0.5), blurRadius: 15)],
                        ),
                        child: Icon(
                          _isRecording ? Icons.pause : Icons.mic,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    
                    if (!_isRecording && _seconds > 0)
                      GestureDetector(
                        onTap: _finishRecording,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: AppColors.mintGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 32, color: Colors.white),
                        ),
                      )
                    else
                      const SizedBox(width: 64),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
