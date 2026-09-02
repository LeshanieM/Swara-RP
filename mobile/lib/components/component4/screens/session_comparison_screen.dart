import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class SessionComparisonScreen extends StatelessWidget {
  const SessionComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 13, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'කාලයත් සමඟ සන්නිවේදනය',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Communication Over Time',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    _buildComparisonCard(
                      title: 'MLU',
                      val1: '4.1',
                      val2: '5.2',
                      description: 'Increased from Session 1',
                      icon: Icons.show_chart,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonCard(
                      title: 'NDW',
                      val1: '28',
                      val2: '37',
                      description: 'More different words were used',
                      icon: Icons.bar_chart,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonCard(
                      title: 'Response Duration',
                      val1: '01:05',
                      val2: '01:24',
                      description: 'Longer spontaneous response',
                      icon: Icons.timer,
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/next_session'),
                      child: const Text('View Next Step'),
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

  Widget _buildComparisonCard({
    required String title,
    required String val1,
    required String val2,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.lgAll,
        boxShadow: AppElevation.card,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text('Session 1', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(val1, style: AppTextStyles.heading2.copyWith(color: AppColors.textLight)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight, size: 32),
              ),
              Column(
                children: [
                  Text('Session 2', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(val2, style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: AppRadii.pillAll,
            ),
            child: Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
