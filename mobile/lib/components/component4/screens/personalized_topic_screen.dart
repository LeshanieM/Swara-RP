import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class PersonalizedTopicScreen extends StatelessWidget {
  const PersonalizedTopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 5, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/component3/lion_mascot.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep,
                        borderRadius: AppRadii.xsAll,
                      ),
                      child: Text(
                        'YOUR TOPIC',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ඔයාගේ මාතෘකාව',
                      style: AppTextStyles.label.copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'මගේ ප්‍රියතම සත්වයා',
                      style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'My Favourite Animal',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildChip('Animals'),
                        _buildChip('Age 7–12'),
                        _buildChip('Easy'),
                        _buildChip('Familiarity 5/5'),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'මේ ගැන කතා කරමුද?',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/question'),
                      child: const Text('ඔව්, කතා කරමු!'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // In a real app this would load a different topic
                        context.push('/c4/question');
                      },
                      child: const Text('වෙනත් මාතෘකාවක්'),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.smAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption,
      ),
    );
  }
}
