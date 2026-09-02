import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({super.key});

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
                'අද අපි මේ කතාව කරමු! 💬',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primaryDeep,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Today\'s Talking Activity',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 48),

              // Large Task Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/component4/c4_picture_story.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Picture Story',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '“මේ පින්තූරය බලලා කතාවක් කියන්න.”',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.text,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(Look at this picture and tell a story.)',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),

              // Small explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'මේ ක්‍රියාකාරකම ඔයාගේ කතා ගමනට ගැලපෙන විදිහට තෝරලා තියෙනවා.',
                            style: AppTextStyles.label.copyWith(color: AppColors.success),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This activity was selected to match your talking journey.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // CTA
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                ),
                onPressed: () {
                  context.pushReplacement('/c4/preparation');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'හරි, කතා කරමු! →',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Okay, let\'s talk!',
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
}
