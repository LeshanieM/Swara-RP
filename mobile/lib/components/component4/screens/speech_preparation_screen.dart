import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class SpeechPreparationScreen extends StatelessWidget {
  const SpeechPreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 7, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'කතා කරන්න සූදානම්ද?',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to talk?',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                        border: Border.all(color: AppColors.primaryWash, width: 2),
                      ),
                      child: Text(
                        '“ඔයාගේ ප්‍රියතම බල්ලා එක්ක දවසක්ම ගත කරන්න පුළුවන් නම්, ඔයා දෙන්නා මොනවා කරයිද?”',
                        style: AppTextStyles.heading3.copyWith(color: AppColors.text, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: AppRadii.lgAll,
                      child: Image.asset(
                        'assets/images/camera_mascot.png',
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTip('ඔයාගේ පිළිතුර ගැන ටිකක් හිතන්න.', 'Think about your answer.', Icons.lightbulb_outline),
                    const SizedBox(height: 16),
                    _buildTip('ස්වභාවිකව කතා කරන්න.', 'Speak naturally.', Icons.chat_bubble_outline),
                    const SizedBox(height: 16),
                    _buildTip('කාලය අරගෙන කතා කරන්න.', 'Take your time.', Icons.timer_outlined),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/c4/record'),
                      icon: const Icon(Icons.mic, color: AppColors.white),
                      label: const Text('Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
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

  Widget _buildTip(String sinhala, String english, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primaryWash,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sinhala,
                style: AppTextStyles.titleMedium,
              ),
              Text(
                english,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
