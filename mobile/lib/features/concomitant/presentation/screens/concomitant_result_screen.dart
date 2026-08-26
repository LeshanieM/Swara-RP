import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantResultScreen extends StatelessWidget {
  final Map<String, dynamic>? resultData;
  const ConcomitantResultScreen({super.key, this.resultData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c2Gradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🎥 Secondary Behavior Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Component 2 — Multimodal Video & Audio Analysis', style: TextStyle(color: AppColors.softYellow, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Disclaimer Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.softYellow, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Note: These are AI-based observations, not a formal clinical diagnosis.',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Results Summary Table Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Observed Secondary Behaviors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      const SizedBox(height: 4),
                      const Text('Multimodal visual and acoustic indicators', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      const Divider(height: 24),

                      _buildTableRow('Eye Blinking', 'Detected', AppColors.coralRed, 'Confidence: 88%'),
                      const Divider(height: 16),
                      _buildTableRow('Head Movement', 'Occasional', AppColors.ctaOrange, 'Confidence: 76%'),
                      const Divider(height: 16),
                      _buildTableRow('Facial Tension', 'Low', AppColors.mintGreen, 'Confidence: 92%'),
                      const Divider(height: 16),
                      _buildTableRow('Hand Movement', 'Moderate', AppColors.ctaOrange, 'Confidence: 81%'),
                      const Divider(height: 16),
                      _buildTableRow('Speech Blocks', 'Detected', AppColors.coralRed, 'Confidence: 85%'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/activities'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Proceed to Component 3 Therapy', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(String behavior, String observation, Color statusColor, String confidence) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(behavior, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 15)),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(observation, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(confidence, textAlign: TextAlign.end, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ),
      ],
    );
  }
}
