import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechCompletionScreen extends StatelessWidget {
  final int durationSeconds;

  const SpeechCompletionScreen({super.key, required this.durationSeconds});

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: AppColors.cardCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎉', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 32),
                const Text('Great Job! 🎉', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 8),
                const Text('නියමයි! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                const SizedBox(height: 24),
                
                const Text('You completed the speaking activity.', style: TextStyle(fontSize: 16, color: AppColors.text)),
                const SizedBox(height: 4),
                const Text('ඔබ කථන ක්‍රියාකාරකම සාර්ථකව අවසන් කළා.', style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                const SizedBox(height: 40),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('Speaking Duration', style: TextStyle(fontSize: 16, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      const Text('කථන කාලය', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      Text(_formatTime(durationSeconds), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
                    ],
                  ),
                ),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pushReplacement('/c1/result', extra: durationSeconds),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Column(
                      children: [
                         Text('Continue to Analysis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                         Text('විශ්ලේෂණයට යන්න', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
