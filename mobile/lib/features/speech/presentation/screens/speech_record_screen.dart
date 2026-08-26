import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechRecordScreen extends ConsumerStatefulWidget {
  final String childId;

  const SpeechRecordScreen({super.key, required this.childId});

  @override
  ConsumerState<SpeechRecordScreen> createState() => _SpeechRecordScreenState();
}

class _SpeechRecordScreenState extends ConsumerState<SpeechRecordScreen> with SingleTickerProviderStateMixin {
  int _currentActivity = 0; // 0 = Reading Practice, 1 = Picture Description
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecorded = false;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _hasRecorded = false;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _hasRecorded = true;
    });
  }

  void _resetRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _hasRecorded = false;
      _seconds = 0;
    });
  }

  void _nextActivityOrFinish() {
    if (_currentActivity == 0) {
      setState(() {
        _currentActivity = 1;
        _hasRecorded = false;
        _seconds = 0;
      });
    } else {
      context.pushReplacement('/c1/result');
    }
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentActivity == 0 ? 'Activity 1: Reading Practice' : 'Activity 2: Picture Description',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text("Component 1 — Speech Assessment", style: TextStyle(color: AppColors.softYellow, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        '${_currentActivity + 1}/2',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.jewelEmerald),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_currentActivity == 0) _buildReadingTask() else _buildPictureTask(),
                      const SizedBox(height: 24),

                      // Timer & Animation
                      if (_isRecording) ...[
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(color: AppColors.coralRed, shape: BoxShape.circle),
                              child: const Icon(Icons.mic, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            _formatTime(_seconds),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],

                      if (_hasRecorded) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.mintGreen, borderRadius: BorderRadius.circular(24)),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Recording Completed! 🌟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('Duration: ${_formatTime(_seconds)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Encouragement Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🌟 ', style: TextStyle(fontSize: 20)),
                            Text(
                              'Take your time! / ඔයාට පුළුවන්!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Control Buttons
                      if (!_isRecording && !_hasRecorded) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.ctaOrange,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic, color: Colors.white, size: 28),
                                SizedBox(width: 10),
                                Text('Start Recording', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_isRecording) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _pauseRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.softYellow,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(_isPaused ? 'Resume' : 'Pause', style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _stopRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.coralRed,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text('Stop Recording', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetRecording,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _nextActivityOrFinish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ctaOrange,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(
                                  _currentActivity == 0 ? 'Next Activity' : 'Continue to Results',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📖 ', style: TextStyle(fontSize: 24)),
              Text('Reading Practice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'අද උදෑසන නදී සහ ඇගේ මිතුරන් පාසල් වත්තට ගියා. ඔවුන් එහි තිබූ ලස්සන මල් පැල නිරීක්ෂණය කළා. පසුව ඔවුන් ගුරුවරිය සමඟ එකතු වී වත්ත පිරිසිදු කළා.',
            style: TextStyle(fontSize: 20, height: 1.6, color: AppColors.text, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPictureTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🖼️ ', style: TextStyle(fontSize: 24)),
              Text('Picture Description Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 12),
          // Park Scene Illustration Box
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softYellow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.softYellow, width: 2),
            ),
            child: const Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🌳 👨‍👩‍👧‍👦 🐕 ⚽ 🌸 🛝', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 8),
                    Text('Family playing in the park', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Look at the picture and tell us what you see.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'පින්තූරය බලලා ඔයා දකින දේ ගැන අපිට කියන්න.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
