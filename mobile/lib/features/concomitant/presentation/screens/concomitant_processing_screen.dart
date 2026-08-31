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
    {'en': 'Detecting face', 'si': 'මුහුණ හඳුනාගනිමින්'},
    {'en': 'Tracking head movement', 'si': 'හිස චලනය නිරීක්ෂණය කරමින්'},
    {'en': 'Analyzing eye blinks', 'si': 'ඇස් පිළිසැරීම විශ්ලේෂණය කරමින්'},
    {'en': 'Analyzing facial movement', 'si': 'මුහුණේ චලනය විශ්ලේෂණය කරමින්'},
    {'en': 'Detecting hand/body movement', 'si': 'අත්/ශරීර චලනයන් හඳුනාගනිමින්'},
    {'en': 'Calculating physical behavior score', 'si': 'ශාරීරික හැසිරීම් දර්ශකය ගණනය කරමින්'},
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              const Text(
                'Analyzing Your Video',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ඔබගේ වීඩියෝව විශ්ලේෂණය කරමින් පවතී',
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
                      strokeWidth: 12,
                      backgroundColor: AppColors.divider,
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const Text(
                        'Analyzing...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
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
                                  ? AppColors.mintGreen 
                                  : (isActive ? AppColors.primaryWash : AppColors.surfaceRaised),
                              border: Border.all(
                                color: isCompleted ? AppColors.mintGreen : (isActive ? AppColors.primary : AppColors.divider),
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                                    color: isPending ? AppColors.textLight : AppColors.text,
                                  ),
                                ),
                                Text(
                                  _stages[index]['si']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPending ? AppColors.textLight.withOpacity(0.5) : AppColors.primary,
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
