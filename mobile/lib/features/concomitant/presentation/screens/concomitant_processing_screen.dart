import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'dart:async';

class ConcomitantProcessingScreen extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  const ConcomitantProcessingScreen({super.key, required this.assessmentData});

  @override
  State<ConcomitantProcessingScreen> createState() => _ConcomitantProcessingScreenState();
}

class _ConcomitantProcessingScreenState extends State<ConcomitantProcessingScreen> {
  double _progress = 0;
  int _currentStage = 0;
  
  final List<Map<String, String>> _stages = [
    {'en': 'Noticing expressions ✨', 'si': 'මුහුණේ හැඟීම් බලමින්'},
    {'en': 'Observing head movements 🙂', 'si': 'හිස චලනය නිරීක්ෂණය කරමින්'},
    {'en': 'Counting gentle blinks 👀', 'si': 'ඇස් පිළිසැරීම බලමින්'},
    {'en': 'Seeing lip movements 👄', 'si': 'කතා කිරීමේ රටා බලමින්'},
    {'en': 'Noticing jaw movements 👋', 'si': 'කතා කිරීමේ බලමින්'},
    {'en': 'Gathering Swara\'s observations 🌱', 'si': 'ස්වරගේ නිරීක්ෂණ සූදානම් කරමින්'},
  ];

  @override
  void initState() {
    super.initState();
    _startMockAnalysis();
  }

  void _startMockAnalysis() {
    // Mock progress over 6 seconds
    const totalDuration = Duration(seconds: 6);
    const updateInterval = Duration(milliseconds: 100);
    final totalSteps = totalDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    int currentStep = 0;

    Timer.periodic(updateInterval, (timer) {
      if (currentStep >= totalSteps) {
        timer.cancel();
        if (mounted) {
          context.pushReplacement('/c2/result', extra: widget.assessmentData);
        }
        return;
      }

      setState(() {
        _progress = currentStep / totalSteps;
        _currentStage = (_progress * _stages.length).floor().clamp(0, _stages.length - 1);
      });
      currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Soft lavender
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              const Text(
                'Swara is Thinking... 💭',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ස්වර කල්පනා කරමින් පවතී',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),

              // Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF3E8FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const Text(
                        'Wait a moment...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Stages List
              Expanded(
                child: ListView.builder(
                  itemCount: _stages.length,
                  itemBuilder: (context, index) {
                    final isCompleted = index < _currentStage;
                    final isActive = index == _currentStage;
                    final isPending = index > _currentStage;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted 
                                  ? AppColors.success 
                                  : (isActive ? const Color(0xFFF3E8FF) : Colors.white),
                              border: Border.all(
                                color: isCompleted ? AppColors.success : (isActive ? AppColors.primary : const Color(0xFFE5E7EB)),
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                : (isActive 
                                    ? const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                                      )
                                    : const SizedBox()),
                          ),
                          const SizedBox(width: 16),
                          
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _stages[index]['en']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isActive || isCompleted ? FontWeight.w800 : FontWeight.w600,
                                    color: isPending ? AppColors.mutedText : AppColors.primaryDeep,
                                  ),
                                ),
                                Text(
                                  _stages[index]['si']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isPending ? AppColors.mutedText.withOpacity(0.5) : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
