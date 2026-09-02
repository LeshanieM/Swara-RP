import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> assessmentData;

  const ConcomitantSuccessScreen({super.key, required this.assessmentData});

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final int duration = assessmentData['duration'] ?? 0;
    final String formattedDuration = _formatTime(duration);

    return Scaffold(
      backgroundColor: AppColors.background, // Soft lavender
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Check Badge
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryWash,
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.success, // Mint
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Title
                  const Text(
                    'Great job!',
                    style: TextStyle(
                      color: AppColors.primaryDeep, // Deep purple
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Your speaking session has been recorded successfully.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.divider,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Session Duration
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryWash,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SESSION DURATION',
                                    style: TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDuration,
                                    style: const TextStyle(
                                      color: AppColors.primaryDeep,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Divider
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          height: 2,
                          color: AppColors.divider,
                        ),

                        // Row 2: Recording Type
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryWash,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.videocam_rounded,
                                color: AppColors.success,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RECORDING TYPE',
                                    style: TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Row(
                                    children: [
                                      Text(
                                        'Audio + Video',
                                        style: TextStyle(
                                          color: AppColors.primaryDeep,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.check_rounded,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to processing screen
                        context.pushReplacement('/c2/process', extra: assessmentData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Soft lavender primary
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                        shadowColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
