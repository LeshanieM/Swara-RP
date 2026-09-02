import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ChildResultScreen extends StatelessWidget {
  const ChildResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Swara Speech'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDeep,
        automaticallyImplyLeading: false,
        actions: [
          // Professional SLP View button
          IconButton(
            icon: const Icon(Icons.analytics, color: AppColors.textLight),
            onPressed: () {
              context.push('/c4/report');
            },
            tooltip: 'SLP / Professional Dashboard',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/component4/c4_celebration.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Text(
                'මගේ කතා ගමන 🌱',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primaryDeep,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'My Talking Journey',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 48),
              
              _buildJourneyCard(
                '💬',
                'අද මම කතා කළා',
                'Activity completed',
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              
              _buildJourneyCard(
                '📖',
                'මගේ කතාව',
                'You shared your ideas with Swara',
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              
              _buildJourneyCard(
                '⭐',
                'අදගේ තරුව',
                'You completed today\'s talking activity',
                AppColors.warning,
              ),
              const SizedBox(height: 16),
              
              _buildJourneyCard(
                '🌱',
                'දිගටම කතා කරමු',
                'Every conversation is a chance to share your ideas.',
                AppColors.success,
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                ),
                onPressed: () {
                  context.go('/');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏠', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      'ගෙදර යන්න (Go Home)',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCard(String emoji, String titleSi, String titleEn, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleSi,
                  style: AppTextStyles.heading3.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  titleEn,
                  style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
