import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class CommunicationTaskScreen extends StatefulWidget {
  final String childId;
  const CommunicationTaskScreen({super.key, required this.childId});

  @override
  State<CommunicationTaskScreen> createState() => _CommunicationTaskScreenState();
}

class _CommunicationTaskScreenState extends State<CommunicationTaskScreen> {
  int? _selectedTopic;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecorded = false;
  int _seconds = 0;
  Timer? _timer;

  final List<Map<String, String>> _topics = [
    {
      'emoji': '🏫',
      'titleEn': 'Topic 1 — At School',
      'titleSi': 'පාසලේදී',
      'promptEn': 'Tell me about your school day.',
      'promptSi': 'අද පාසලේ සිදුවුණු දේවල් ගැන මට කියන්න.',
    },
    {
      'emoji': '🛒',
      'titleEn': 'Topic 2 — Going to a Shop',
      'titleSi': 'කඩයකට යාම',
      'promptEn': 'Imagine you are going to a shop. Tell me what you would do.',
      'promptSi': 'ඔයා කඩයකට යනවා කියලා හිතන්න. ඔයා එහිදී කරන දේවල් ගැන කියන්න.',
    },
    {
      'emoji': '👫',
      'titleEn': 'Topic 3 — Meeting a Friend',
      'titleSi': 'යාළුවෙක් හමුවීම',
      'promptEn': 'Imagine you meet your friend after school. What would you talk about?',
      'promptSi': 'පාසලෙන් පස්සේ ඔයාට යාළුවෙක් හමුවෙනවා කියලා හිතන්න. ඔයා එයා එක්ක මොනවා ගැන කතා කරයිද?',
    },
    {
      'emoji': '⚽',
      'titleEn': 'Topic 4 — Favourite Activity',
      'titleSi': 'කැමතිම ක්‍රියාව',
      'promptEn': 'Tell me about something you really enjoy doing.',
      'promptSi': 'ඔයා ගොඩක් කැමති දෙයක් ගැන මට කියන්න.',
    },
  ];

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _hasRecorded = false;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) setState(() => _seconds++);
    });
  }

  void _pauseRecording() {
    setState(() => _isPaused = !_isPaused);
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _hasRecorded = true;
    });
  }

  void _submitRecording() {
    context.pushReplacement('/c4/result');
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c4Gradient,
        ),
        child: SafeArea(
          child: _selectedTopic == null ? _buildTopicSelection() : _buildSpontaneousRecording(),
        ),
      ),
    );
  }

  Widget _buildTopicSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌱 Component 4: Spontaneous Speech', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Natural Communication Generalization', style: TextStyle(color: AppColors.softYellow, fontSize: 12)),
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
                const Text('Generate Spontaneous Topic', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Select a familiar real-life communication scenario.', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 20),

                ...List.generate(_topics.length, (index) {
                  final topic = _topics[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTopic = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardCream,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Text(topic['emoji']!, style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topic['titleEn']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                                Text(topic['promptSi']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: AppColors.ctaOrange, size: 18),
                        ],
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpontaneousRecording() {
    final topic = _topics[_selectedTopic!];
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  _timer?.cancel();
                  setState(() { _selectedTopic = null; _isRecording = false; _hasRecorded = false; _seconds = 0; });
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic['titleEn']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Spontaneous Speaking Task', style: TextStyle(color: AppColors.softYellow, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(topic['emoji']!, style: const TextStyle(fontSize: 70)),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    children: [
                      Text(topic['promptEn']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(topic['promptSi']!, style: const TextStyle(fontSize: 14, color: AppColors.textLight), textAlign: TextAlign.center),
                      const Divider(height: 24),
                      const Text('There is no right or wrong answer. Just talk naturally.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.jewelEmerald)),
                      const Text('හරි හෝ වැරදි පිළිතුරක් නැහැ. ස්වාභාවිකව කතා කරන්න.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isRecording) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                    child: Text(_formatTime(_seconds), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],

                const SizedBox(height: 28),

                if (!_isRecording && !_hasRecorded)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startRecording,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mic, color: Colors.white, size: 28), SizedBox(width: 10), Text('Start Recording', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))]),
                    ),
                  )
                else if (_isRecording)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pauseRecording,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.softYellow, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: Text(_isPaused ? 'Resume' : 'Pause', style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _stopRecording,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralRed, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: const Text('Stop Recording', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _hasRecorded = false),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: const Text('Replay / Re-record', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitRecording,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaOrange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: const Text('Submit Task', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
