import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechResultScreen extends StatefulWidget {
  final String assessmentId;
  const SpeechResultScreen({super.key, required this.assessmentId});

  @override
  State<SpeechResultScreen> createState() => _SpeechResultScreenState();
}

class _SpeechResultScreenState extends State<SpeechResultScreen> {
  bool _isProcessing = true;
  int _currentStep = 0;
  int _viewMode = 0; // 0 = Child View, 1 = Clinician View

  final List<Map<String, String>> _steps = [
    {'si': 'කතාව ලැබුණා', 'en': 'Speech Received'},
    {'si': 'කතා කිරීම සකස් කළා', 'en': 'Audio Prepared'},
    {'si': 'කතා කරන ආකාරය බලමින්', 'en': 'Analyzing Speech'},
    {'si': 'ප්‍රතිඵල සූදානම් කරමින්', 'en': 'Preparing Results'}
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _currentStep = i);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: _isProcessing ? _buildProcessing() : _buildResultsDashboard(),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.softYellow, shape: BoxShape.circle),
            child: const Text('🔍', style: TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing Speech Fluency...\nඔයාගේ කතාව බලමින්...',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _steps.length; i++)
                  _buildStepIndicator(_steps[i], i < _currentStep, i == _currentStep, i > _currentStep),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(Map<String, String> step, bool isCompleted, bool isCurrent, bool isWaiting) {
    IconData iconData = isCompleted ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked);
    Color iconColor = isCompleted ? AppColors.mintGreen : (isCurrent ? AppColors.ctaOrange : AppColors.divider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['en']!, style: TextStyle(color: isWaiting ? AppColors.textLight : AppColors.text, fontSize: 16, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                Text(step['si']!, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Mode Switcher (Child vs Clinician View)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _viewMode == 0 ? AppColors.ctaOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Text('🧒 Child View', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _viewMode == 1 ? AppColors.ctaOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Text('🩺 Clinician View', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_viewMode == 0) _buildChildView() else _buildClinicianView(),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaOrange,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Continue to Home Quest', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.softYellow, shape: BoxShape.circle),
          child: const Text('🌟', style: TextStyle(fontSize: 60)),
        ),
        const SizedBox(height: 16),
        const Text('Speech Activity Completed! 🎉', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text('ගොඩක් හොඳයි! ඔයා හොඳින් කළා.', style: TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
          child: const Column(
            children: [
              _InfoRow(icon: Icons.check_circle_outline, label: 'Activity Status', value: 'Completed 2/2 Tasks'),
              Divider(height: 24),
              _InfoRow(icon: Icons.timer_outlined, label: 'Practice Time', value: '1 min 30 sec'),
              Divider(height: 24),
              _InfoRow(icon: Icons.star_border, label: 'Fluency Progress', value: 'Great effort today! ⭐'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicianView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.jewelEmerald, size: 28),
              SizedBox(width: 10),
              Text('Speech Fluency Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          SizedBox(height: 4),
          Text('Evidence-oriented preliminary observations', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          Divider(height: 28),

          _MetricRow(label: 'Total Speech Duration', value: '90.4s'),
          _MetricRow(label: 'Speaking Rate (SPM)', value: '142 syllables/min'),
          _MetricRow(label: 'Pause Count', value: '8 pauses (>1.5s)'),
          _MetricRow(label: 'Stuttering Event Count', value: '6 events'),
          _MetricRow(label: '% Syllables Stuttered (%SS)', value: '4.2%'),
          _MetricRow(label: 'Speech Fluency Score', value: '82 / 100'),
          
          Divider(height: 24),
          Text('Disfluency Types Identified', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ChipMetric(label: 'Repetitions', count: '3'),
              _ChipMetric(label: 'Prolongations', count: '2'),
              _ChipMetric(label: 'Blocks', count: '1'),
            ],
          ),

          Divider(height: 24),
          Text('Reading vs Picture-Description Comparison', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
          SizedBox(height: 8),
          _ComparisonBar(task: 'Reading Task', score: '90%', color: AppColors.mintGreen),
          SizedBox(height: 6),
          _ComparisonBar(task: 'Picture Description', score: '74%', color: AppColors.softYellow),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ctaOrange, size: 24),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.jewelEmerald)),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ChipMetric extends StatelessWidget {
  final String label;
  final String count;
  const _ChipMetric({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.softYellow.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
      child: Text('$label: $count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text)),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String task;
  final String score;
  final Color color;
  const _ComparisonBar({required this.task, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 130, child: Text(task, style: const TextStyle(fontSize: 12, color: AppColors.text))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: double.parse(score.replaceAll('%', '')) / 100, color: color, backgroundColor: AppColors.divider, minHeight: 12),
          ),
        ),
        const SizedBox(width: 10),
        Text(score, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
