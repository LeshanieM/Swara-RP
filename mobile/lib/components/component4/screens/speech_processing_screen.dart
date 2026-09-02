import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class SpeechProcessingScreen extends StatefulWidget {
  const SpeechProcessingScreen({super.key});

  @override
  State<SpeechProcessingScreen> createState() => _SpeechProcessingScreenState();
}

class _SpeechProcessingScreenState extends State<SpeechProcessingScreen> {
  int _activeStage = 1; // 0 completed, 1 processing

  final List<Map<String, dynamic>> _stages = [
    {'title': 'Speech Recorded', 'icon': Icons.mic},
    {'title': 'Sinhala Speech → Text', 'icon': Icons.translate},
    {'title': 'Language Analysis', 'icon': Icons.analytics},
    {'title': 'Communication Results', 'icon': Icons.assignment},
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  void _startProcessing() async {
    for (int i = 1; i <= _stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _activeStage = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _activeStage >= _stages.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 9, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: Column(
                  children: [
                    Text(
                      isComplete ? 'විශ්ලේෂණය සම්පූර්ණයි' : 'ඔයාගේ කථනය විශ්ලේෂණය කරමින්...',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete ? 'Analysis Complete' : 'Understanding your speech...',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ...List.generate(_stages.length, (index) {
                      return _buildProcessRow(index, _stages[index]['title']!, _stages[index]['icon']);
                    }),
                    const SizedBox(height: 48),
                    if (isComplete)
                      ElevatedButton(
                        onPressed: () {
                          Future.microtask(() => context.push('/c4/transcription'));
                        },
                        child: const Text('View Transcript'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessRow(int stageIndex, String title, IconData icon) {
    bool isCompleted = _activeStage > stageIndex;
    bool isCurrent = _activeStage == stageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success.withOpacity(0.1) : (isCurrent ? AppColors.primaryWash : AppColors.surfaceRaised),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted ? AppColors.success : (isCurrent ? AppColors.primary : AppColors.textLight.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isCompleted ? AppColors.text : (isCurrent ? AppColors.primaryDeep : AppColors.textLight.withOpacity(0.5)),
                  ),
                ),
                Text(
                  isCompleted ? 'Completed' : (isCurrent ? 'Processing...' : 'Waiting'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (isCurrent)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
