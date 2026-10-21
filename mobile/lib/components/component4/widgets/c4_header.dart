import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class C4Header extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBackPressed;

  const C4Header({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360 ? 18.0 : 22.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: AppColors.surfaceRaised,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'ආපසු',
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    onPressed: onBackPressed ??
                        () {
                          Future.microtask(() {
                            if (context.mounted) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            }
                          });
                        },
                    color: AppColors.text,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'කථන ක්‍රියාකාරකම',
                      style: AppTextStyles.heading3
                          .copyWith(fontSize: titleSize, color: AppColors.text),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'පියවර $currentStep / $totalSteps',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: AppColors.primaryWash,
          color: AppColors.primary,
          minHeight: 3,
        ),
      ],
    );
  }
}
