import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantDashboardScreen extends ConsumerStatefulWidget {
  final String childId;

  const ConcomitantDashboardScreen({super.key, required this.childId});

  @override
  ConsumerState<ConcomitantDashboardScreen> createState() => _ConcomitantDashboardScreenState();
}

class _ConcomitantDashboardScreenState extends ConsumerState<ConcomitantDashboardScreen> {
  int _selectedOption = 0; // 0 = Option B (Use Component 1), 1 = Option A (Upload Video)
  bool _hasVideoSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c2Gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 26),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🎥 Secondary Behavior Analysis', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Component 2 — Multimodal Video & Audio', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Video Input Source',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Analyze facial tension, eye blinking, posture, and speech blocks.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),

                      // Input Selector Tabs
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedOption = 0),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _selectedOption == 0 ? AppColors.cardCream : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _selectedOption == 0 ? AppColors.ctaOrange : Colors.transparent, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Text('🎤 Option B', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedOption == 0 ? AppColors.text : Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('Use Comp 1 Recording', style: TextStyle(fontSize: 11, color: _selectedOption == 0 ? AppColors.textLight : Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedOption = 1),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _selectedOption == 1 ? AppColors.cardCream : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _selectedOption == 1 ? AppColors.ctaOrange : Colors.transparent, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Text('📁 Option A', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedOption == 1 ? AppColors.text : Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('Upload Video File', style: TextStyle(fontSize: 11, color: _selectedOption == 1 ? AppColors.textLight : Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_selectedOption == 0) _buildOptionB() else _buildOptionA(),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.push('/c2/process', extra: {'childId': widget.childId}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ctaOrange,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Analyze Video & Audio', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionB() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.video_library, color: AppColors.jewelNavy, size: 24),
              SizedBox(width: 8),
              Text('Previous Activity Recording', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.softYellow.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.jewelEmerald),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Component 1: Picture Description Task', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 14)),
                      Text('Recorded today • Duration: 1 min 30 sec', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('This video recording will be automatically used for multimodal analysis.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildOptionA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Video File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('Upload a speaking video for analysis (MP4, MOV up to 50MB).', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => setState(() => _hasVideoSelected = !_hasVideoSelected),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardCream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.ctaOrange, width: 2, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_hasVideoSelected ? Icons.video_file : Icons.cloud_upload_outlined, size: 48, color: AppColors.ctaOrange),
                    const SizedBox(height: 8),
                    Text(
                      _hasVideoSelected ? 'speaking_video_sample.mp4 selected' : 'Tap to select video from device',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _hasVideoSelected ? AppColors.jewelEmerald : AppColors.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
