import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class StorybookScreen extends StatefulWidget {
  final String childId;

  const StorybookScreen({super.key, required this.childId});

  @override
  State<StorybookScreen> createState() => _StorybookScreenState();
}

class _StorybookScreenState extends State<StorybookScreen> {
  int _selectedActivity = 0; // 0=Breathing, 1=Relaxation, 2=Easy Speaking, 3=Picture Speaking

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.c3Gradient, // Purple backdrop
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
                      Text('📖 Component 3: Guided Therapy', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Interactive Fluency Activities', style: TextStyle(color: Color(0xFF0066CC), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            // Launch Forest Adventure Therapy Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/c3/forest-therapy'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066CC), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Text('🌲', style: TextStyle(fontSize: 26)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forest Adventure Speech Therapy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Open 18-Screen Adventure Journey (6 Themes)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Activity Navigation Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildActivityTab(0, '🫁 Breathing', 'සන්සුන් හුස්මක්'),
                  _buildActivityTab(1, '🧘 Relaxation', 'සන්සුන් වෙමු'),
                  _buildActivityTab(2, '💬 Easy Speaking', 'කෑම / සතා'),
                  _buildActivityTab(3, '🖼️ Picture Speaking', 'පින්තූර කතා'),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_selectedActivity == 0) _BreathingWidget(onComplete: () => setState(() => _selectedActivity = 1)),
                    if (_selectedActivity == 1) _RelaxationWidget(onComplete: () => setState(() => _selectedActivity = 2)),
                    if (_selectedActivity == 2) _EasySpeakingWidget(onComplete: () => setState(() => _selectedActivity = 3)),
                    if (_selectedActivity == 3) _PictureSpeakingWidget(onComplete: () => _showCompletionDialog(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab(int index, String title, String subtitle) {
    final isSelected = _selectedActivity == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedActivity = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066CC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066CC) : const Color(0xFF0066CC).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF0066CC).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext parentContext) {
    final router = GoRouter.of(parentContext);
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardCream,
        title: const Row(
          children: [
            Text('🌟 ', style: TextStyle(fontSize: 32)),
            Text('Great job! 🎉', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'You completed today\'s therapy activities!\nඔයා අද ක්‍රියාකාරකම් සාර්ථකව කළා.',
          style: TextStyle(fontSize: 16, color: AppColors.text),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              router.go('/c4/task'); // Safe navigation without unmounted context assertion
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange),
            child: const Text('Proceed to Component 4 (Spontaneous Task)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Activity 1: Breathing
class _BreathingWidget extends StatefulWidget {
  final VoidCallback onComplete;
  const _BreathingWidget({required this.onComplete});

  @override
  State<_BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<_BreathingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _repCount = 0;
  String _phase = "Breathe in slowly...";
  String _phaseSi = "සෙමින් හුස්ම ගන්න...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward) {
          if (mounted) {
            setState(() {
              _phase = "Breathe in slowly...";
              _phaseSi = "සෙමින් හුස්ම ගන්න...";
            });
          }
        } else if (status == AnimationStatus.reverse) {
          if (mounted) {
            setState(() {
              _phase = "Breathe out slowly...";
              _phaseSi = "සෙමින් හුස්ම පිට කරන්න...";
              _repCount++;
            });
          }
          if (_repCount >= 3) {
            _controller.stop();
          }
        }
      })
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          const Text('Calm Breathing / සන්සුන් හුස්මක් ගමු', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 20),

          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Container(
                width: 140 + (_controller.value * 60),
                height: 140 + (_controller.value * 60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mintGreen.withOpacity(0.4 + (_controller.value * 0.4)),
                  border: Border.all(color: AppColors.mintGreen, width: 4),
                ),
                child: const Center(child: Text('🫁', style: TextStyle(fontSize: 60))),
              );
            },
          ),
          const SizedBox(height: 24),

          Text(_phase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.jewelEmerald)),
          Text(_phaseSi, style: const TextStyle(fontSize: 16, color: AppColors.textLight)),
          const SizedBox(height: 16),
          Text('Repetition: $_repCount / 3', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange),
            child: const Text('Next Activity (Relaxation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Activity 2: Relaxation
class _RelaxationWidget extends StatelessWidget {
  final VoidCallback onComplete;
  const _RelaxationWidget({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          const Text('Relax & Get Ready / සන්සුන් වෙමු', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 16),
          _stepCard('1', 'Relax your shoulders.', 'උරහිස් ලිහිල් කරන්න.'),
          _stepCard('2', 'Take a slow breath.', 'සෙමින් හුස්මක් ගන්න.'),
          _stepCard('3', 'Relax your face.', 'මුහුණේ මාංශ පේශී ලිහිල් කරන්න.'),
          _stepCard('4', 'Get ready to speak comfortably.', 'පහසුවෙන් කතා කිරීමට සූදානම් වෙන්න.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange),
            child: const Text('Next Activity (Easy Speaking)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(String num, String en, String si) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.softYellow.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.ctaOrange, radius: 14, child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(en, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                Text(si, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Activity 3: Easy Speaking
class _EasySpeakingWidget extends StatelessWidget {
  final VoidCallback onComplete;
  const _EasySpeakingWidget({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          const Text('Easy Speaking Practice / පහසුවෙන් කතා කරමු', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 16),
          const Text('What is your favourite food?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.jewelEmerald)),
          const Text('ඔයා කැමතිම කෑම මොකක්ද?', style: TextStyle(fontSize: 16, color: AppColors.textLight)),
          const SizedBox(height: 24),
          const CircleAvatar(radius: 40, backgroundColor: AppColors.coralRed, child: Icon(Icons.mic, size: 40, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange),
            child: const Text('Next Activity (Picture Speaking)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Activity 4: Picture Speaking
class _PictureSpeakingWidget extends StatelessWidget {
  final VoidCallback onComplete;
  const _PictureSpeakingWidget({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          const Text('Picture-Based Speaking / පින්තූර කතා', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 16),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.softYellow.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('🎨 🏫 ⚽', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 14),
          const Text('Tell me what is happening in this picture.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const Text('මේ පින්තූරයේ සිදුවෙන්නේ මොකක්ද කියලා කියන්න.', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange),
            child: const Text('Complete Component 3 Activities! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
