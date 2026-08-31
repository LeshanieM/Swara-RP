import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechTaskScreen extends StatefulWidget {
  const SpeechTaskScreen({super.key});

  @override
  State<SpeechTaskScreen> createState() => _SpeechTaskScreenState();
}

class _SpeechTaskScreenState extends State<SpeechTaskScreen> with SingleTickerProviderStateMixin {
  int? _selectedAgeGroup; // 0 = 4-7, 1 = 7-15
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
    context.pushReplacement('/c1/complete', extra: _seconds);
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 26),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAgeGroup == null ? 'Select Age' : (_selectedAgeGroup == 0 ? 'Picture Description' : 'Reading Practice'),
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text("Component 1 — Speech Assessment", style: TextStyle(color: Color(0xFF0066CC), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _selectedAgeGroup == null ? _buildAgeSelection() : _buildTask(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('How old are you?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('ඔයාගෙ වයස කීයද?', style: TextStyle(fontSize: 16, color: AppColors.textLight)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAgeGroup = 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardCream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Column(
                      children: [
                        Text('👧👦', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Age 4–7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAgeGroup = 1),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardCream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Column(
                      children: [
                        Text('🧑👩', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Age 7–15', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTask() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_selectedAgeGroup == 0) _buildPictureTask() else _buildReadingTask(),
          const SizedBox(height: 32),

          // Timer & Animation
          if (_isRecording) ...[
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: AppColors.coralRed, shape: BoxShape.circle),
                  child: const Icon(Icons.mic, color: Colors.white, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _formatTime(_seconds),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coralRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Stop Recording', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaOrange,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(_selectedAgeGroup == 0 ? 'Start Speaking' : 'Start Reading', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedAgeGroup == 0 ? 'කතා කිරීම ආරම්භ කරන්න' : 'කියවීම ආරම්භ කරන්න',
              style: const TextStyle(fontSize: 16, color: AppColors.text, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPictureTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let's Talk About This Picture!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text("මේ පින්තූරය ගැන අපි කතා කරමු!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          const SizedBox(height: 20),
          // Picture Box
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softYellow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.softYellow, width: 2),
            ),
            child: const Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🌳 👨‍👩‍👧‍👦 🐕 ⚽ 🌸 🛝', style: TextStyle(fontSize: 42)),
                    SizedBox(height: 12),
                    Text('Family playing in the park', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Look at the picture and tell us what you see.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'පින්තූරය බලලා ඔබ දකින දේ ගැන කතා කරන්න.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Read the Paragraph", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          SizedBox(height: 4),
          Text("ඡේදය කියවන්න", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          SizedBox(height: 20),
          Text(
            'Please read the following paragraph aloud.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          SizedBox(height: 4),
          Text(
            'පහත ඡේදය ශබ්ද නඟා කියවන්න.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 24),
          Text(
            'අද උදෑසන නදී සහ ඇගේ මිතුරන් පාසල් වත්තට ගියා. ඔවුන් එහි තිබූ ලස්සන මල් පැල නිරීක්ෂණය කළා. පසුව ඔවුන් ගුරුවරිය සමඟ එකතු වී වත්ත පිරිසිදු කළා. මෙම කාර්යය ඔවුන්ට ඉතා සතුටක් ගෙන දුන්නා.',
            style: TextStyle(fontSize: 22, height: 1.8, color: AppColors.text, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
