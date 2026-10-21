import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'dart:async';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _pipeline = [
 
  {
    'icon': Icons.mic_none_rounded,
    'titleEn': 'Speech Captured',
    'titleSi': 'කතාව ලබාගත්තා',
    'desc': 'ඔයාගේ කථන නියැදිය සූදානම්.',
    'color': AppColors.primary
  },
  {
    'icon': Icons.translate_rounded,
    'titleEn': 'Transcription',
    'titleSi': 'කතාව වචන වලට හරවනවා',
    'desc': 'කථනය ලිඛිත වචන බවට පරිවර්තනය කරමින්...',
    'color': AppColors.primary
  },
  {
    'icon': Icons.text_fields_rounded,
    'titleEn': 'NDW Calculated',
    'titleSi': 'NDW ගණනය කරනවා',
    'desc': 'වෙනස් වචන ගණන ගණනය කරමින්...',
    'color': AppColors.lilacTint
  },
  {
    'icon': Icons.format_size_rounded,
    'titleEn': 'MLU Calculated',
    'titleSi': 'MLU ගණනය කරනවා',
    'desc': 'සාමාන්‍ය ප්‍රකාශන දිග මනිමින්...',
    'color': AppColors.primaryLight
  },
  {
    'icon': Icons.graphic_eq_rounded,
    'titleEn': 'Speech Flow Analysis',
    'titleSi': 'කතා ප්‍රවාහ විශ්ලේෂණය',
    'desc': 'කාලය, කථන වේගය සහ විරාම විශ්ලේෂණය කරමින්...',
    'color': AppColors.groundBreathe
  },
  {
    'icon': Icons.hearing_rounded,
    'titleEn': 'Fluency Check',
    'titleSi': 'සුමට බව පරීක්ෂාව',
    'desc': 'වචන නැවතීම් සහ පැකිළීම් හඳුනාගනිමින්...',
    'color': AppColors.coralTint
  },
  {
    'icon': Icons.auto_awesome_rounded,
    'titleEn': 'Preparing Results',
    'titleSi': 'ප්‍රතිඵල සකස් කරනවා',
    'desc': 'තව මොහොතකින් සූදානම්!',
    'color': AppColors.sunTint
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
      if (i == 2 || i == 3 || i == 4 || i == 5)
        delay = 3500; // longer for calculation visuals
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
      backgroundColor: AppColors.groundRead,
      body: SafeArea(
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.primaryDeep),
                      ),
                      Text(
                        'සියල්ල සූදානම්!',
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
                        'ඔයාගේ කතාව ගැන බලමු!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primaryDeep,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
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

                      return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCurrent ? AppColors.primary : AppColors.primaryLight,
                              width: isCurrent ? 3 : 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(step['icon'] as IconData,
                                      size: 30,
                                      color: AppColors.primary),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '0${index + 1} — ${step['titleSi']}',
                                          style:
                                              AppTextStyles.heading3.copyWith(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          step['desc'] as String,
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.primary, size: 28)
                                  else
                                    Icon(
                                      isCurrent ? Icons.more_time_rounded : Icons.circle_outlined,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isCompleted ? 'සම්පූර්ණයි' : isCurrent ? 'සකසමින්...' : 'ඉදිරියට ඇත',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                              ),
                              // Visual calculations for specific steps – now showing metrics
                              if (isCurrent && index == 2) _buildNDWVisual(),
                              if (isCurrent && index == 3) _buildMLUVisual(),
                              if (isCurrent && index == 4)
                                _buildSpeechFlowVisual(),
                              if (isCurrent && index == 5)
                                _buildFluencyVisual(),
                            ],
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        context.pushReplacement('/c4/child_result');
                      },
                      child: const Text('මගේ ප්‍රතිඵල බලමු →',
                          style: TextStyle(
                              fontSize: 18,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
        ),
      ),
    );
  }

  // Updated: now displays NDW metric instead of Sinhala word bubbles
  Widget _buildNDWVisual() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('වෙනස් වචන ගණන (NDW)',
              style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text('42',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.primary, fontSize: 32)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['ඇපල්', 'පාසල', 'මිතුරා', 'සෙල්ලම්', 'ලොකු', 'කුඩා']
                .map((w) => Chip(
                    label: Text(w), backgroundColor: Colors.purple.shade50))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Updated: now displays MLU metric instead of Sinhala sentence examples
  Widget _buildMLUVisual() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('සාමාන්‍ය ප්‍රකාශන දිග (MLU)',
              style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text('වචන 4.0ක්',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.primary, fontSize: 32)),
          const SizedBox(height: 8),
          Text('ප්‍රකාශනවල වචන ගණන: 3, 5, 4, 2, 6',
              style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
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
              Container(width: 30, height: 8, color: AppColors.primary),
              Container(width: 15, height: 8, color: AppColors.primaryLight),
              Container(width: 40, height: 8, color: AppColors.primary),
              Container(width: 10, height: 8, color: AppColors.primaryLight),
              Container(width: 25, height: 8, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text('කාලය: 01:12',
              style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text('කථන වේගය: තත්පරයට අක්ෂර 2.8ක්',
              style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text('විරාම: 7 (සාමාන්‍යයෙන් තත්පර 1.1ක්)',
              style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text('පිළිතුර ආරම්භ කිරීමට: තත්පර 2.4ක්',
              style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildFluencyVisual() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 48),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('හඳුනාගත් කථන පැකිළීම්: 8',
              style: AppTextStyles.label.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  // Helper (not used for metrics now, but kept for reference)
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
