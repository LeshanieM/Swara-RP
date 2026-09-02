import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  const ConcomitantResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Very light lavender
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text, size: 28),
          onPressed: () => context.go('/'),
        ),
        title: const Column(
          children: [
            Text('⭐ Swara\'s Observations', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('ස්වරගේ නිරීක්ෂණ', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 32),
              _buildOverallScore(),
              const SizedBox(height: 24),
              _buildIndividualResults(),
              const SizedBox(height: 24),
              _buildTimeline(),
              const SizedBox(height: 24),
              _buildScoreSummary(),
              const SizedBox(height: 32),
              
              // Finish Button
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Soft lavender primary
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Back to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.home_rounded, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceRaised,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.primaryWash, blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: const Text('👋', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Great job talking!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Swara quietly observed your communication patterns.\nHere is what we noticed!',
          style: TextStyle(fontSize: 15, color: AppColors.textLight, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOverallScore() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: AppColors.divider, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: 0.72,
                  strokeWidth: 14,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success), // Mint green
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌱', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 4),
                  Text('72%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Gentle Observation Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Text('නිරීක්ෂණ ලකුණු', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(16)), // Pale mint
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.success, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You are doing wonderful! We are learning how you talk.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIndividualResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What We Noticed ✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 16),
        _buildDetectionCard(
          emoji: '👀',
          titleEn: 'Eye Blinking',
          titleSi: 'ඇස් පිළිසැරීම',
          mainValue: '27 detected',
          details: ['Gentle blinks observed: 27', 'Pace: 15.9/min'],
          bgColor: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF3B82F6),
        ),
        _buildDetectionCard(
          emoji: '😊',
          titleEn: 'Facial Movement',
          titleSi: 'මුහුණේ චලනය',
          mainValue: '12 moments',
          details: ['Expression changes: 12', 'Smoothness: 84%'],
          bgColor: const Color(0xFFFEF2F2),
          iconColor: AppColors.error,
        ),
        _buildDetectionCard(
          emoji: '👄',
          titleEn: 'Jaw/Lip Movements',
          titleSi: 'හකු/තොල් චලනයන්',
          mainValue: '15 moments',
          details: ['Speaking articulations: 15', 'Average intensity: 42%'],
          bgColor: const Color(0xFFFFFBEB),
          iconColor: AppColors.warning,
        ),
        _buildDetectionCard(
          emoji: '🙂',
          titleEn: 'Head Movements',
          titleSi: 'හිස චලනයන්',
          mainValue: '18 noticed',
          details: ['Soft nods: 18', 'Duration involved: 8.4 sec'],
          bgColor: AppColors.primaryWash,
          iconColor: AppColors.success,
        ),
        _buildDetectionCard(
          emoji: '👋',
          titleEn: 'Hand Movements',
          titleSi: 'අත් චලනයන්',
          mainValue: '9 moments',
          details: ['Gestures made: 9', 'Average duration: 1.2 sec'],
          bgColor: AppColors.primaryWash,
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDetectionCard({
    required String emoji,
    required String titleEn,
    required String titleSi,
    required String mainValue,
    required List<String> details,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.divider, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleEn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                    Text(titleSi, style: TextStyle(fontSize: 13, color: iconColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(20)),
                child: Text(mainValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textLight)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: iconColor.withOpacity(0.5)),
                const SizedBox(width: 10),
                Text(d, style: const TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('〰️ Sound Wave Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Text('හැසිරීම් කාලරේඛාව', style: TextStyle(fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight)),
              Text('01:42', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4))),
              _buildTimelineMarker(0.14, AppColors.success), // Head
              _buildTimelineMarker(0.18, const Color(0xFF3B82F6)), // Blink
              _buildTimelineMarker(0.30, AppColors.error), // Facial
              _buildTimelineMarker(0.46, AppColors.warning), // Jaw/Lip
              _buildTimelineMarker(0.62, AppColors.primary), // Hand
            ],
          ),
          const SizedBox(height: 24),
          // Selected point mock
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Text('👄', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jaw/Lip Movement', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF6D28D9))),
                      Text('A moment you were talking', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                ),
                Text('00:47', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(double percent, Color color) {
    return Positioned(
      left: percent * 300, // Roughly layout width
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      ),
    );
  }

  Widget _buildScoreSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Quick Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Text('සාරාංශය', style: TextStyle(fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 20),
          _buildSummaryBar('Eye blinking', 0.35, const Color(0xFF3B82F6)),
          _buildSummaryBar('Facial movement', 0.25, AppColors.error),
          _buildSummaryBar('Jaw/Lip movements', 0.20, AppColors.warning),
          _buildSummaryBar('Head movements', 0.10, AppColors.success),
          _buildSummaryBar('Hand movements', 0.10, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text))),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(5)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
