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
          color: AppColors.background, // Soft lavender background
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDeep, size: 28),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🎈 Let\'s Talk with Swara', style: TextStyle(color: AppColors.primaryDeep, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Swara is listening and watching you talk', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                        'How would you like to start? ✨',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDeep),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can use a video we just made, or pick a new one.',
                        style: TextStyle(fontSize: 15, color: AppColors.primary),
                      ),
                      const SizedBox(height: 24),

                      // Input Selector Tabs
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedOption = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedOption == 0 ? Colors.white : const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _selectedOption == 0 ? AppColors.primary : Colors.transparent, width: 3),
                                  boxShadow: [
                                    if (_selectedOption == 0) const BoxShadow(color: AppColors.primaryWash, blurRadius: 12, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text('🌟', style: TextStyle(fontSize: _selectedOption == 0 ? 28 : 24)),
                                    const SizedBox(height: 8),
                                    Text('Use Last Video', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _selectedOption == 0 ? AppColors.primaryDeep : AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedOption = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedOption == 1 ? Colors.white : const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _selectedOption == 1 ? AppColors.primary : Colors.transparent, width: 3),
                                  boxShadow: [
                                    if (_selectedOption == 1) const BoxShadow(color: AppColors.primaryWash, blurRadius: 12, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text('✨', style: TextStyle(fontSize: _selectedOption == 1 ? 28 : 24)),
                                    const SizedBox(height: 8),
                                    Text('Pick New Video', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _selectedOption == 1 ? AppColors.primaryDeep : AppColors.primary)),
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
                            backgroundColor: AppColors.primary, // Primary purple
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 4,
                            shadowColor: AppColors.primary,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Let\'s Go! 🚀', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📼', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Text('Previous Adventure', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDeep)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(24)),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Picture Description Task', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF065F46), fontSize: 15)),
                      Text('Recorded today • 1 min 30 sec', style: TextStyle(fontSize: 13, color: Color(0xFF047857))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Swara will quietly listen to this video and learn how you speak! 🌱', style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildOptionA() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload New Video', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDeep)),
          const SizedBox(height: 8),
          const Text('Pick a fun video of you talking (MP4 or MOV).', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => setState(() => _hasVideoSelected = !_hasVideoSelected),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _hasVideoSelected ? AppColors.primaryWash : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _hasVideoSelected ? AppColors.success : const Color(0xFFE5E7EB), width: 3, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_hasVideoSelected ? Icons.video_file_rounded : Icons.cloud_upload_rounded, size: 56, color: _hasVideoSelected ? AppColors.success : AppColors.mutedText),
                    const SizedBox(height: 12),
                    Text(
                      _hasVideoSelected ? 'speaking_video_sample.mp4 selected ✨' : 'Tap to select a video',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _hasVideoSelected ? const Color(0xFF065F46) : AppColors.textLight),
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
