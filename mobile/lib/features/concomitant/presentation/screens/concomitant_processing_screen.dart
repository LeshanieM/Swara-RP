import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import '../../data/providers/concomitant_provider.dart';

class ConcomitantProcessingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> assessmentData;
  const ConcomitantProcessingScreen({super.key, required this.assessmentData});

  @override
  ConsumerState<ConcomitantProcessingScreen> createState() => _ConcomitantProcessingScreenState();
}

class _ConcomitantProcessingScreenState extends ConsumerState<ConcomitantProcessingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'කතාව ලැබුණා',
    'ශබ්දය බලමින්',
    'කතා කරන වෙලාවේ සිදුවන දේ බලමින්',
    'ප්‍රතිඵල සූදානම් කරමින්'
  ];
  String? _error;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      for (int i = 0; i < _steps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) setState(() => _currentStep = i);
      }

      final provider = ref.read(component2MockProvider);
      final result = await provider.getAssessmentResults('mock-session-id');

      if (mounted) {
        context.pushReplacement('/c2/result/${result.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: Text('🌟', style: TextStyle(fontSize: 80))),
              const SizedBox(height: 32),
              Text('ඔයාගේ කතාව බලමින්...', style: AppTextStyles.heading1.copyWith(color: AppColors.component2Lavender, fontSize: 28), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () { setState(() => _error = null); _startProcessing(); }, child: const Text('නැවත උත්සාහ කරන්න')),
              ] else ...[
                for (int i = 0; i < _steps.length; i++)
                  _buildStepIndicator(_steps[i], i < _currentStep, i == _currentStep, i > _currentStep),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(String text, bool isCompleted, bool isCurrent, bool isWaiting) {
    IconData iconData;
    Color iconColor;

    if (isCompleted) {
      iconData = Icons.check_circle;
      iconColor = AppColors.success;
    } else if (isCurrent) {
      iconData = Icons.radio_button_checked;
      iconColor = AppColors.component2Lavender;
    } else {
      iconData = Icons.radio_button_unchecked;
      iconColor = AppColors.divider;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isWaiting ? AppColors.textLight : AppColors.deepNavy,
                fontSize: 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCurrent)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.component2Lavender)),
        ],
      ),
    );
  }
}
