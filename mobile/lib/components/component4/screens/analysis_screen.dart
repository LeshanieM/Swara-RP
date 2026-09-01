import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  
  final List<Map<String, dynamic>> _pipeline = [
    {'icon': Icons.mic_rounded, 'text': 'Listening to you...', 'color': Colors.blue},
    {'icon': Icons.draw_rounded, 'text': 'Writing down words...', 'color': Colors.orange},
    {'icon': Icons.auto_awesome, 'text': 'Understanding the story...', 'color': Colors.purple},
    {'icon': Icons.celebration, 'text': 'All done!', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _startAnalysis();
  }

  void _startAnalysis() async {
    for (int i = 0; i < _pipeline.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      context.pushReplacement('/c4/report');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.1).animate(_pulseController),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const Icon(Icons.rocket_launch, size: 80, color: Colors.blueAccent),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Magic in Progress! ✨',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primaryDeep,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: List.generate(_pipeline.length, (index) {
                      final step = _pipeline[index];
                      final isActive = index <= _currentStep;
                      final isCurrent = index == _currentStep;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isActive ? step['color'].withOpacity(0.2) : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step['icon'] as IconData,
                                color: isActive ? step['color'] : Colors.grey.shade400,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                step['text'] as String,
                                style: AppTextStyles.heading3.copyWith(
                                  color: isActive ? AppColors.text : Colors.grey.shade400,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isCurrent)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            else if (isActive)
                              const Icon(Icons.check_circle, color: Colors.green, size: 28)
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 48),
                if (_currentStep >= 1) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orange.shade200, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text('I heard you say:', style: AppTextStyles.label.copyWith(color: Colors.orange.shade800)),
                        const SizedBox(height: 8),
                        Text(
                          '“පිරිමි ළමයා බල්ලා එක්ක සෙල්ලම් කරනවා. බල්ලා දුවනවා.”',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading3.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const SizedBox(height: 100), // Placeholder height
              ],
            ),
          ),
        ),
      ),
    );
  }
}
