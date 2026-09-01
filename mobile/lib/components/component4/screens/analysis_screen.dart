import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'dart:async';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  
  final List<Map<String, dynamic>> _pipeline = [
    {
      'icon': '🎙️', 
      'titleEn': 'Speech Captured',
      'titleSi': 'කතාව ලබාගත්තා',
      'desc': 'Your talking sample is ready.',
      'color': Colors.blue
    },
    {
      'icon': '📝', 
      'titleEn': 'Speech Transcribed',
      'titleSi': 'කතාව වචන වලට හරවනවා',
      'desc': 'Understanding the spoken words...',
      'color': Colors.orange
    },
    {
      'icon': '💬', 
      'titleEn': 'Finding Words',
      'titleSi': 'වචන හඳුනාගන්නවා',
      'desc': 'Looking at the words you used...',
      'color': Colors.purple
    },
    {
      'icon': '🧩', 
      'titleEn': 'Language Patterns',
      'titleSi': 'භාෂා රටා බලනවා',
      'desc': 'Exploring your language patterns...',
      'color': Colors.indigo
    },
    {
      'icon': '📊', 
      'titleEn': 'Calculating Measures',
      'titleSi': 'භාෂා මිනුම් ගණනය කරනවා',
      'desc': 'Calculating language measurements...',
      'color': Colors.teal
    },
    {
      'icon': '🌱', 
      'titleEn': 'Preparing Results',
      'titleSi': 'ප්‍රතිඵල සකස් කරනවා',
      'desc': 'Almost ready!',
      'color': Colors.green
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _startAnalysis();
  }

  void _startAnalysis() async {
    for (int i = 0; i < _pipeline.length; i++) {
      int delay = 2000;
      if (i == 2 || i == 3 || i == 4) delay = 3500; // longer for calculation visuals
      await Future.delayed(Duration(milliseconds: delay));
      if (mounted) {
        setState(() {
          _currentStep = i + 1;
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      context.pushReplacement('/c4/child_result');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFinished = _currentStep >= _pipeline.length;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isFinished)
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/component4/c4_celebration.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ඔයාගේ කතා ගමන සූදානම්!',
                        style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep),
                      ),
                      Text(
                        'All done!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primaryDeep,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        'Let\'s explore your story 🌱',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primaryDeep,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ඔයාගේ කතාව ගැන බලමු!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 32),
                
                // Pipeline visualization
                Expanded(
                  child: ListView.builder(
                    itemCount: _pipeline.length,
                    itemBuilder: (context, index) {
                      final step = _pipeline[index];
                      final isCompleted = _currentStep > index;
                      final isCurrent = _currentStep == index;
                      
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: (isCompleted || isCurrent) ? 1.0 : 0.3,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.white : (isCompleted ? step['color'].withOpacity(0.05) : Colors.transparent),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCurrent ? step['color'] : (isCompleted ? step['color'].withOpacity(0.3) : Colors.transparent),
                              width: 2,
                            ),
                            boxShadow: isCurrent ? [
                              BoxShadow(color: step['color'].withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                            ] : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(step['icon'] as String, style: const TextStyle(fontSize: 32)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '0${index + 1} — ${step['titleEn']}',
                                          style: AppTextStyles.heading3.copyWith(
                                            color: isCurrent ? step['color'] : AppColors.text,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${step['titleSi']} - ${step['desc']}',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    Icon(Icons.check_circle, color: step['color'], size: 28)
                                  else if (isCurrent)
                                    SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(color: step['color'], strokeWidth: 3),
                                    ),
                                ],
                              ),
                              // Visual calculations for specific steps
                              if (isCurrent && index == 2) _buildNDWVisual(),
                              if (isCurrent && index == 3) _buildMLUVisual(),
                              if (isCurrent && index == 4) _buildSpeechFlowVisual(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                if (isFinished)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 4,
                      ),
                      onPressed: () {
                        context.pushReplacement('/c4/child_result');
                      },
                      child: const Text('See My Results (මගේ ප්‍රතිඵල බලමු) →', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNDWVisual() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAnimatedWordBubble('බල්ලා', Colors.orange),
              const SizedBox(width: 8),
              _buildAnimatedWordBubble('පාසල', Colors.blue),
              const SizedBox(width: 8),
              _buildAnimatedWordBubble('මිතුරා', Colors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Text('Different words found: 42', style: AppTextStyles.label.copyWith(color: Colors.purple)),
        ],
      ),
    );
  }
  
  Widget _buildMLUVisual() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('මම | පාසලට | ගියා (3 words)', style: AppTextStyles.caption.copyWith(color: Colors.indigo)),
          const SizedBox(height: 4),
          Text('මම | යාළුවා | එක්ක | සෙල්ලම් | කළා (5 words)', style: AppTextStyles.caption.copyWith(color: Colors.indigo)),
          const SizedBox(height: 12),
          Text('Average utterance length: 4.0 words', style: AppTextStyles.label.copyWith(color: Colors.indigo)),
        ],
      ),
    );
  }
  
  Widget _buildSpeechFlowVisual() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 30, height: 8, color: Colors.teal),
              Container(width: 15, height: 8, color: Colors.teal.shade100),
              Container(width: 40, height: 8, color: Colors.teal),
              Container(width: 10, height: 8, color: Colors.teal.shade100),
              Container(width: 25, height: 8, color: Colors.teal),
            ],
          ),
          const SizedBox(height: 12),
          Text('Speech rate: 2.8 w/s', style: AppTextStyles.label.copyWith(color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildAnimatedWordBubble(String word, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade300),
      ),
      child: Text(word, style: TextStyle(color: color.shade800, fontSize: 12)),
    );
  }
}
