import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class PersonalizationProcessScreen extends StatefulWidget {
  const PersonalizationProcessScreen({super.key});

  @override
  State<PersonalizationProcessScreen> createState() => _PersonalizationProcessScreenState();
}

class _PersonalizationProcessScreenState extends State<PersonalizationProcessScreen> {
  int _activeStage = 0;

  final List<Map<String, String>> _stages = [
    {'title': 'Animals', 'subtitle': 'Your Interests'},
    {'title': 'Familiarity: 5/5', 'subtitle': 'Knowledge Level'},
    {'title': 'Age: 9', 'subtitle': 'Child Profile'},
    {'title': 'Matching validated topics...', 'subtitle': 'SLP Topic Bank'},
    {'title': 'My Favourite Animal', 'subtitle': 'Personalized Topic'},
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < _stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _activeStage = i;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.push('/c4/topic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 4, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ඔයාට ගැළපෙන මාතෘකාවක් සොයමින්...',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Finding a topic just for you...',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    for (int i = 0; i < _stages.length; i++) ...[
                      _buildStageCard(i),
                      if (i < _stages.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _activeStage >= i ? 1.0 : 0.2,
                            child: const Icon(Icons.arrow_downward, color: AppColors.primaryLight),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(int index) {
    final isActive = _activeStage == index;
    final isCompleted = _activeStage > index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryWash
            : (isCompleted ? AppColors.surfaceRaised : AppColors.surface),
        borderRadius: AppRadii.lgAll,
        border: Border.all(
          color: isActive ? AppColors.primary : (isCompleted ? AppColors.divider : Colors.transparent),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? AppElevation.card : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  _stages[index]['title']!,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isActive || isCompleted ? AppColors.primaryDeep : AppColors.textLight.withOpacity(0.5),
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isActive || isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    _stages[index]['subtitle']!,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),
          if (isActive)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}
