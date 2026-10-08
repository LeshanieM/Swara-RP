import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class LinguisticAnalysisScreen extends StatefulWidget {
  const LinguisticAnalysisScreen({super.key});

  @override
  State<LinguisticAnalysisScreen> createState() => _LinguisticAnalysisScreenState();
}

class _LinguisticAnalysisScreenState extends State<LinguisticAnalysisScreen> {
  int _activeStage = 0; // 0: audio, 1: MLU, 2: NDW, 3: duration, 4: complete
  int _mluStep = 0;
  int _ndwStep = 0;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    // Audio summary shows first
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _activeStage = 1);
    
    // MLU calculation
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _mluStep = i);
    }
    
    if (mounted) setState(() => _activeStage = 2);

    // NDW calculation
    for (int i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() => _ndwStep = i);
    }

    if (mounted) setState(() => _activeStage = 3);
    
    // Duration
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) setState(() => _activeStage = 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 11, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _activeStage == 4 ? 'විශ්ලේෂණය සම්පූර්ණයි' : 'ඔයාගේ කථනය විශ්ලේෂණය කරමින්...',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeStage == 4 ? 'Analysis Complete' : 'Analysing Your Speech',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_activeStage < 4)
                      Text(
                        'We are analysing the language used in your response.',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),

                    // Audio Summary Card
                    _buildCard(
                      title: 'Recorded Speech',
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq, color: AppColors.primary, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sinhala Speech', style: AppTextStyles.titleMedium),
                                Text('01:24', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MLU Calculation
                    if (_activeStage >= 1)
                      _buildCard(
                        title: 'Calculating MLU',
                        subtitle: 'සාමාන්‍ය ප්‍රකාශන දිග',
                        child: Column(
                          children: [
                            if (_mluStep >= 1) _buildCalcStep('Scanning utterances...', '12 utterances detected'),
                            if (_mluStep >= 2) _buildCalcStep('Counting words...', '62 total words'),
                            if (_mluStep >= 3) _buildCalcStep('MLU = Total Words ÷ Number of Utterances', '62 ÷ 12'),
                            if (_mluStep >= 4)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  children: [
                                    Text('5.2', style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 48)),
                                    Text('words / utterance', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // NDW Calculation
                    if (_activeStage >= 2)
                      _buildCard(
                        title: 'Calculating NDW',
                        subtitle: 'වෙනස් වචන ගණන',
                        child: Column(
                          children: [
                            if (_ndwStep >= 1) _buildCalcStep('Extract words from transcript', '62 words'),
                            if (_ndwStep >= 2) _buildCalcStep('Identify unique words', '37 unique words'),
                            if (_ndwStep >= 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  children: [
                                    Text('37', style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 48)),
                                    Text('Different Words', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Response Duration
                    if (_activeStage >= 3)
                      _buildCard(
                        title: 'Response Duration',
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Start: 00:00', style: AppTextStyles.bodySmall),
                                const Icon(Icons.arrow_forward, size: 16, color: AppColors.textLight),
                                Text('End: 01:24', style: AppTextStyles.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('01:24', style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 32)),
                            Text('Total speaking response duration', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                    
                    if (_activeStage < 4)
                      Column(
                        children: [
                          Text('Analysis Progress', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_activeStage * 25 + (_mluStep * 5) + (_ndwStep * 5)) / 100.0,
                          ),
                        ],
                      ),

                    if (_activeStage == 4)
                      ElevatedButton(
                        onPressed: () => context.push('/c4/results'),
                        child: const Text('View Results →'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, String? subtitle, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.lgAll,
        boxShadow: AppElevation.card,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.text)),
          if (subtitle != null) ...[
            Text(subtitle, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCalcStep(String title, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodySmall)),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.divider),
          const SizedBox(width: 8),
          Text(result, style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
        ],
      ),
    );
  }
}
