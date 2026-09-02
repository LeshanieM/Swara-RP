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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: onBackPressed ?? () {
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
                color: AppColors.primaryDeep,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Component 4',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'පුද්ගලීකරණය කළ කථන ක්‍රියාකාරකම',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$currentStep / $totalSteps',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: AppColors.primaryWash,
          color: AppColors.primary,
          minHeight: 2,
        ),
      ],
    );
  }
}
