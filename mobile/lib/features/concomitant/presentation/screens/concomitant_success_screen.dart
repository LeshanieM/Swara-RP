import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      backgroundColor: const Color(0xFFF4F6FB),
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
                      color: Color(0xFFE3F6EE),
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F7A5C),
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
                      color: Color(0xFF2F5CF0),
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
                        color: Color(0xFF3A3F4B),
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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141E3C).withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
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
                                color: const Color(0xFFE8EEFD),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF2F5CF0),
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
                                      color: Color(0xFF8A8F9C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDuration,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1D29),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Divider
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 14),
                          height: 1,
                          color: const Color(0xFFEDF0F5),
                        ),

                        // Row 2: Recording Type
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2E9FB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.videocam_outlined,
                                color: Color(0xFF8B3FD6),
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
                                      color: Color(0xFF8A8F9C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Text(
                                        'Audio + Video',
                                        style: TextStyle(
                                          color: Color(0xFF1A1D29),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFF0F7A5C),
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
                        backgroundColor: const Color(0xFF2F5CF0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
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
