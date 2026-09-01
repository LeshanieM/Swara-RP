import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Swara Speech'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDeep,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'කතාව කියන්න ලෑස්තිද? 🎙️',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primaryDeep,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to tell your story?',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 48),

              _buildStepCard(
                '1',
                '🎤',
                'මයික් එක ළඟින් කතා කරන්න.',
                'Speak near the microphone.',
                Colors.blue,
              ),
              const SizedBox(height: 16),
              
              _buildStepCard(
                '2',
                '💬',
                'ඔයාට පහසු විදිහට කතා කරන්න.',
                'Speak comfortably in your own way.',
                Colors.orange,
              ),
              const SizedBox(height: 16),
              
              _buildStepCard(
                '3',
                '🌱',
                'ඉක්මන් වෙන්න ඕනේ නැහැ.',
                'Take your time, no need to rush.',
                Colors.green,
              ),
              
              const SizedBox(height: 48),
              
              Text(
                'මම ලෑස්තියි! (I\'m ready!)',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDeep),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                ),
                onPressed: () {
                  context.pushReplacement('/c4/record');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'කතා කරන්න පටන් ගමු 🎙️',
                      style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s start speaking',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryDeep),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(String number, String emoji, String titleSi, String titleEn, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleSi,
                  style: AppTextStyles.heading3.copyWith(color: color.shade800, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  titleEn,
                  style: AppTextStyles.caption.copyWith(color: color.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
