import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class NewConcomitantAssessmentScreen extends ConsumerStatefulWidget {
  final String childId;
  const NewConcomitantAssessmentScreen({super.key, required this.childId});

  @override
  ConsumerState<NewConcomitantAssessmentScreen> createState() => _NewConcomitantAssessmentScreenState();
}

class _NewConcomitantAssessmentScreenState extends ConsumerState<NewConcomitantAssessmentScreen> {
  int _selectedIndex = 0;
  final List<Map<String, String>> _tasks = [
    {'si': 'කතාවක් කියවීම', 'en': 'Reading a Story', 'emoji': '📖'},
    {'si': 'පින්තූරයක් විස්තර කිරීම', 'en': 'Describing a Picture', 'emoji': '🖼️'},
    {'si': 'කතාවක් කීම', 'en': 'Telling a Story', 'emoji': '💬'},
    {'si': 'නිකමට කතා කිරීම', 'en': 'Free Talking', 'emoji': '🗣️'},
  ];

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
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🎈 ක්‍රියාකාරකම තෝරන්න', style: TextStyle(color: AppColors.primaryDeep, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Choose Your Activity', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'ඔයා අද මොනවා කරන්නද කැමති?\nWhich activity do you like today?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDeep),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(_tasks.length, (index) => _buildTaskOption(index)),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/c2/record', extra: {
                              'childId': widget.childId,
                              'taskType': _tasks[_selectedIndex]['si'],
                            });
                          },
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
                              Text('යමු! (Let\'s Go)', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white),
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

  Widget _buildTaskOption(int index) {
    final task = _tasks[index];
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 3),
          boxShadow: [
            if (isSelected) const BoxShadow(color: AppColors.primaryWash, blurRadius: 12, offset: Offset(0, 4))
            else const BoxShadow(color: AppColors.divider, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(16)),
              child: Text(task['emoji']!, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['si']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDeep)),
                  Text(task['en']!, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.divider,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
