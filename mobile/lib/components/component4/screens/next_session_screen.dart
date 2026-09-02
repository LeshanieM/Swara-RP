import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class NextSessionScreen extends StatelessWidget {
  const NextSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 14, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'ඊළඟ වතාවේ',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next Time',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ඔයාගේ පෙර සැසියේ තොරතුරු භාවිත කර ඊළඟ කථන ක්‍රියාකාරකම පුද්ගලීකරණය කළ හැක.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your next speaking activity can be personalized using information from your previous session.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Previous Topic
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: AppRadii.lgAll,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadii.mdAll,
                            child: Image.asset(
                              'assets/images/component3/lion_mascot.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Animals', style: AppTextStyles.titleLarge),
                                Text('Previous Topic', style: AppTextStyles.caption),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text('Familiarity: 5 / 5', style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text('Status: Completed', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Icon(Icons.arrow_downward, color: AppColors.primary, size: 32),
                    ),

                    // Next Topic
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        borderRadius: AppRadii.lgAll,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: AppElevation.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDeep,
                              borderRadius: AppRadii.xsAll,
                            ),
                            child: Text(
                              'NEXT PERSONALIZED ACTIVITY',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: AppRadii.mdAll,
                                child: Image.asset(
                                  'assets/images/component3/milo_trophy.jpg',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sports', style: AppTextStyles.titleLarge),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_half, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 4),
                                        Text('Familiarity: 4 / 5', style: AppTextStyles.caption),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Question style:', style: AppTextStyles.caption),
                                    Text(
                                      'Simple → More open-ended',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Finish Activity'),
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
}
