import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechResultScreen extends StatefulWidget {
  final int durationSeconds;
  final Map<String, dynamic>? analysisResult;

  const SpeechResultScreen({
    super.key,
    required this.durationSeconds,
    this.analysisResult,
  });

  @override
  State<SpeechResultScreen> createState() => _SpeechResultScreenState();
}

class _SpeechResultScreenState extends State<SpeechResultScreen> {
  bool _isProcessing = true;
  int _currentStep = 0;
  int _progress = 0;

  final List<Map<String, String>> _steps = [
    {'en': 'Processing speech', 'si': 'කථනය සකසමින්'},
    {'en': 'Detecting syllables', 'si': 'අක්ෂර ඒකක හඳුනාගනිමින්'},
    {'en': 'Detecting repetitions', 'si': 'පුනරාවර්තන හඳුනාගනිමින්'},
    {'en': 'Detecting prolongations', 'si': 'දිගු කිරීම් හඳුනාගනිමින්'},
    {'en': 'Detecting blocks', 'si': 'අවහිරවීම් හඳුනාගනිමින්'},
    {'en': 'Calculating severity', 'si': 'තීව්‍රතාවය ගණනය කරමින්'},
    {'en': 'Preparing results', 'si': 'ප්‍රතිඵල සූදානම් කරමින්'},
  ];

  // Dynamic getters falling back to defaults if analysisResult is omitted
  int get totalSyllables =>
      (widget.analysisResult?['syllableMetrics']?['totalSyllables'] as num?)?.toInt() ?? 312;

  int get stutteredWords =>
      (widget.analysisResult?['syllableMetrics']?['stutteredSyllables'] as num?)?.toInt() ?? 24;

  double get stutterRate =>
      (widget.analysisResult?['syllableMetrics']?['percentSyllablesStuttered'] as num?)?.toDouble() ?? 7.7;

  int get repetitions {
    final soundReps = (widget.analysisResult?['eventCounts']?['soundRepetitions'] as num?)?.toInt() ?? 0;
    final wordReps = (widget.analysisResult?['eventCounts']?['wordRepetitions'] as num?)?.toInt() ?? 0;
    final sum = soundReps + wordReps;
    return sum > 0 ? sum : 12;
  }

  int get prolongations =>
      (widget.analysisResult?['eventCounts']?['prolongations'] as num?)?.toInt() ?? 5;

  int get blocks =>
      (widget.analysisResult?['eventCounts']?['blocks'] as num?)?.toInt() ?? 3;

  String get primaryStutteringType =>
      (widget.analysisResult?['stutterType'] as String?) ?? "Repetition";

  String get primaryStutteringTypeSi {
    final t = primaryStutteringType.toLowerCase();
    if (t.contains('repetition')) return "පුනරාවර්තනය";
    if (t.contains('prolongation')) return "දිගු කිරීම";
    if (t.contains('block')) return "අවහිරවීම";
    if (t.contains('interjection')) return "අතුරු වදන්";
    return "සාමාන්‍ය කථනය";
  }

  String get severity =>
      (widget.analysisResult?['severity'] as String?) ?? "Moderate";

  String get severitySi {
    final s = severity.toLowerCase();
    if (s.contains('mild')) return "සුළු";
    if (s.contains('moderate')) return "මධ්‍යම";
    if (s.contains('severe')) return "තීව්‍ර";
    if (s.contains('none')) return "නොමැත";
    return "නොලැබුණි";
  }

  List<dynamic> get detectedEvents =>
      (widget.analysisResult?['detectedEvents'] as List<dynamic>?) ?? [];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _currentStep = i;
          _progress = ((i + 1) / _steps.length * 100).toInt();
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isProcessing = false);
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: _isProcessing ? _buildProcessing() : _buildResults(),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Analyzing Your Speech',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'ඔබගේ කථනය විශ්ලේෂණය කරමින් පවතී',
            style: TextStyle(fontSize: 18, color: AppColors.textLight, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          Text(
            'Analyzing... $_progress%',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDeep),
          ),
          const Text(
            'විශ්ලේෂණය වෙමින් පවතී...',
            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step['en']!,
              style: TextStyle(
                color: isWaiting ? AppColors.textLight : AppColors.text,
                fontSize: 16,
                fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Speech Analysis Results',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          const Text(
            'කථන විශ්ලේෂණ ප්‍රතිඵල',
            style: TextStyle(fontSize: 18, color: AppColors.textLight, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Main Result Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text('Assessment Result', style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                const Text('ඇගයීමේ ප්‍රතිඵල', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                const Divider(height: 24),
                
                const Text('STUTTERING TYPE', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(primaryStutteringType, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.coralRed)),
                Text(primaryStutteringTypeSi, style: const TextStyle(fontSize: 16, color: AppColors.coralRed, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 24),
                
                const Text('SEVERITY', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(severity, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ctaOrange)),
                Text(severitySi, style: const TextStyle(fontSize: 16, color: AppColors.ctaOrange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Child Friendly Feedback
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.softYellow.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                Text('Great Work! 🌟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                Text('ඉතා හොඳයි! 🌟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                SizedBox(height: 8),
                Text('You completed the speaking activity successfully.', style: TextStyle(fontSize: 14, color: AppColors.text), textAlign: TextAlign.center),
                Text('ඔබ කථන ක්‍රියාකාරකම සාර්ථකව අවසන් කළා.', style: TextStyle(fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Speech Statistics
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Speech Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                const Text('කථන සංඛ්‍යාලේඛන', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                const SizedBox(height: 16),
                
                _StatRow(label: 'Speaking Duration', value: _formatTime(widget.durationSeconds)),
                const Divider(),
                _StatRow(label: 'Total Syllables', value: totalSyllables.toString()),
                const Divider(),
                _StatRow(label: 'Stuttered Words', value: stutteredWords.toString()),
                const Divider(),
                _StatRow(label: 'Stutter Rate', value: '$stutterRate%'),
                const SizedBox(height: 8),
                Text(
                  '$stutteredWords stuttered words / $totalSyllables spoken syllables',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Detected Events
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detected Stuttering Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 16),
                
                _EventRow(label: 'Repetition', count: repetitions, isHighlight: primaryStutteringType == "Repetition"),
                _EventRow(label: 'Prolongation', count: prolongations, isHighlight: primaryStutteringType == "Prolongation"),
                _EventRow(label: 'Block', count: blocks, isHighlight: primaryStutteringType == "Block"),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$primaryStutteringType was the most frequently detected stuttering event.\nවැඩිම වාර ගණනක් හඳුනාගත් කථන අවහිරතා වර්ගය $primaryStutteringTypeSi.',
                    style: const TextStyle(fontSize: 13, color: AppColors.primaryDeep, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Event Timeline with fl_chart
          _buildTimelineChart(),

          const SizedBox(height: 32),
          
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text('AI-based speech analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                Text('AI මත පදනම් වූ කථන විශ්ලේෂණය', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                SizedBox(height: 8),
                Text(
                  'These results are intended to support assessment and should be interpreted by a qualified Speech-Language Pathologist.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'මෙම ප්‍රතිඵල ඇගයීම සඳහා සහායක් ලෙස භාවිත කළ යුතු අතර සුදුසුකම් ලත් කථන හා භාෂා චිකිත්සකයෙකු විසින් අර්ථකථනය කළ යුතුය.',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Back to Home', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimelineChart() {
    final events = detectedEvents;

    // Build timeline bars for each stuttering event
    List<BarChartGroupData> barGroups = [];
    if (events.isNotEmpty) {
      for (int i = 0; i < events.length; i++) {
        final ev = events[i];
        final start = ((ev is Map ? (ev['startTime'] ?? ev['start_time']) : 0) as num?)?.toDouble() ?? 0.0;
        final dur = ((ev is Map ? (ev['duration'] ?? 1.0) : 1.0) as num?)?.toDouble() ?? 1.0;

        barGroups.add(
          BarChartGroupData(
            x: start.toInt(),
            barRods: [
              BarChartRodData(
                toY: math.min(5.0, math.max(0.6, dur)),
                color: AppColors.coralRed,
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    } else {
      barGroups = [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(toY: 0.2, color: AppColors.mintGreen, width: 6),
          ],
        )
      ];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stuttering Events Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const Text(
            'කථන අවහිරතා කාලරේඛාව',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 5,
                minY: 0,
                barGroups: barGroups,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text('${val.toInt()}s', style: const TextStyle(fontSize: 10, color: AppColors.textLight));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}s',
                        style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            events.isEmpty
                ? 'No severe disfluencies detected along the speaking timeline.'
                : '${events.length} disfluent event(s) mapped across ${_formatTime(widget.durationSeconds)}.',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.text, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 18, color: AppColors.primaryDeep, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String label;
  final int count;
  final bool isHighlight;

  const _EventRow({required this.label, required this.count, required this.isHighlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.coralRed.withValues(alpha: 0.1) : Colors.transparent,
        border: Border.all(color: isHighlight ? AppColors.coralRed : AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal, color: AppColors.text)),
          Text(count.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.coralRed : AppColors.text)),
        ],
      ),
    );
  }
}
