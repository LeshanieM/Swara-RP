import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'dart:async';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String get _formattedTime {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🌟 Your Activity 🌟'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDeep,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Playful Image Container
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 6),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.pets, size: 120, color: Colors.orange),
                          Positioned(
                            top: 20,
                            right: 30,
                            child: Icon(Icons.star, color: Colors.yellow.shade700, size: 40),
                          ),
                          Positioned(
                            bottom: 30,
                            left: 40,
                            child: Icon(Icons.favorite, color: Colors.red.shade300, size: 35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Child-friendly prompt
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDeep.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        '“Look at the picture and tell me what is happening.”',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primaryDeep,
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    if (!_isRecording && _seconds == 0) ...[
                      Text('🎤 Ready to Talk?', style: AppTextStyles.heading2.copyWith(color: AppColors.text)),
                      const SizedBox(height: 24),
                      // Big friendly start button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isRecording = true;
                            _startTimer();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ADE80), // Playful Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          elevation: 6,
                          shadowColor: const Color(0xFF4ADE80).withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 32),
                            const SizedBox(width: 12),
                            Text('Start Recording', style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Recording State
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _isRecording ? Colors.red.shade300 : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _formattedTime,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito', // Playful font
                                fontFeatures: const [FontFeature.tabularFigures()],
                                color: _isRecording ? Colors.red.shade400 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Playful waveform
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                15,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 8,
                                  height: _isRecording ? (20.0 + (index % 3) * 15.0 + (index % 2) * 10.0) : 12.0,
                                  decoration: BoxDecoration(
                                    color: _isRecording 
                                        ? Colors.redAccent.shade100 
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom Controls
            if (_seconds > 0)
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            if (_isRecording) {
                              _isRecording = false;
                              _stopTimer();
                            } else {
                              _isRecording = true;
                              _startTimer();
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          _isRecording ? '⏸️ Pause' : '▶️ Resume',
                          style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDeep),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E), // Playful Red
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 4,
                        ),
                        onPressed: () {
                          _stopTimer();
                          context.pushReplacement('/c4/analysis');
                        },
                        child: const Text('🛑 Stop & Finish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
