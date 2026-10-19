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
      (widget.analysisResult?['syllableMetrics']?['totalSyllables'] as num?)?.toInt() ?? 180;

  int get stutteredSyllables =>
      (widget.analysisResult?['syllableMetrics']?['stutteredSyllables'] as num?)?.toInt() ?? 15;

  double get percentSS =>
      (widget.analysisResult?['syllableMetrics']?['percentSyllablesStuttered'] as num?)?.toDouble() ?? 8.3;

  String? get referenceSource =>
      widget.analysisResult?['syllableMetrics']?['referenceSyllablesSource'] as String?;

  // 5 Stuttering categories per Section 3 & Page 4-5
  int get soundRepetitions =>
      (widget.analysisResult?['eventCounts']?['soundRepetitions'] as num?)?.toInt() ?? 5;

  int get prolongations =>
      (widget.analysisResult?['eventCounts']?['prolongations'] as num?)?.toInt() ?? 3;

  int get blocks =>
      (widget.analysisResult?['eventCounts']?['blocks'] as num?)?.toInt() ?? 2;

  int get wordRepetitions =>
      (widget.analysisResult?['eventCounts']?['wordRepetitions'] as num?)?.toInt() ?? 3;

  int get interjections =>
      (widget.analysisResult?['eventCounts']?['interjections'] as num?)?.toInt() ?? 2;

  int get totalEvents =>
      (widget.analysisResult?['eventCounts']?['total'] as num?)?.toInt() ??
      (soundRepetitions + prolongations + blocks + wordRepetitions + interjections);

  // Duration metrics per SSI-4 idea (Page 6)
  double get longestEventDuration =>
      (widget.analysisResult?['durationMetrics']?['longestEventDuration'] as num?)?.toDouble() ?? 2.4;

  double get meanThreeLongestEventsDuration =>
      (widget.analysisResult?['durationMetrics']?['meanThreeLongestEventsDuration'] as num?)?.toDouble() ?? 2.1;

  double? get concomitantScore =>
      (widget.analysisResult?['concomitantScore'] as num?)?.toDouble();

  String get severityEstimateType =>
      (widget.analysisResult?['severityEstimateType'] as String?) ?? "SSI-4-inspired audio-based severity estimate";

  String get clinicalStatus =>
      (widget.analysisResult?['clinicalStatus'] as String?) ?? (severity == "None" ? "No / very mild stuttering detected" : "$severity stuttering detected");

  String get primaryStutteringType =>
      (widget.analysisResult?['stutterType'] as String?) ?? "Sound Repetition";

  String get primaryStutteringTypeSi {
    final t = primaryStutteringType.toLowerCase();
    if (t.contains('sound repetition') || t.contains('soundrep')) return "ශබ්ද පුනරාවර්තනය";
    if (t.contains('word repetition') || t.contains('wordrep')) return "වචන පුනරාවර්තනය";
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
    if (s.contains('none')) return "නොමැත (සාමාන්‍ය)";
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

          // Main Result Summary: Severity & Stuttering Type
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF0066CC)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        severityEstimateType,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0066CC), fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(clinicalStatus, style: const TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                const Divider(height: 24),

                const Text('PRIMARY STUTTERING PATTERN', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(primaryStutteringType, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.coralRed)),
                Text(primaryStutteringTypeSi, style: const TextStyle(fontSize: 15, color: AppColors.coralRed, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                const Text('ESTIMATED SEVERITY LEVEL', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(severity, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ctaOrange)),
                Text(severitySi, style: const TextStyle(fontSize: 16, color: AppColors.ctaOrange, fontWeight: FontWeight.bold)),

                if (concomitantScore != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF86EFAC))),
                    child: Text('📹 Video Concomitant Factor Integrated (C2 Score: ${concomitantScore!.toStringAsFixed(2)})', style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Speech Statistics Card (%SS and SSI-4 Durations)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Speech & %SS Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                const Text('කථන හා %SS මිනුම් (SSI-4 සම්මතය)', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 16),

                _StatRow(label: 'Speaking Duration', value: _formatTime(widget.durationSeconds)),
                const Divider(),
                _StatRow(label: 'Total Spoken Syllables', value: totalSyllables.toString()),
                if (referenceSource != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Source: $referenceSource', style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                  ),
                const Divider(),
                _StatRow(label: 'Stuttered Syllables (%SS)', value: '$percentSS%'),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Text(
                    '%SS = ($stutteredSyllables stuttered / $totalSyllables spoken) × 100',
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryDeep, fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(),
                _StatRow(label: 'Longest Stutter Event', value: '${longestEventDuration.toStringAsFixed(1)}s'),
                const Divider(),
                _StatRow(label: 'Top 3 Events Mean Duration', value: '${meanThreeLongestEventsDuration.toStringAsFixed(1)}s'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detected Stuttering Events Across All 5 Categories
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stuttering Categories (5 Types)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primaryDeep, borderRadius: BorderRadius.circular(12)),
                      child: Text('Total: $totalEvents', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Text('හඳුනාගත් අවහිරතා වර්ග 5', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 16),

                _CategoryRow(
                  title: 'Sound Repetition ("B-b-ball")',
                  sinhalaTitle: 'ශබ්ද පුනරාවර්තනය',
                  count: soundRepetitions,
                  color: const Color(0xFFF59E0B),
                  isPrimary: primaryStutteringType.toLowerCase().contains('sound'),
                ),
                _CategoryRow(
                  title: 'Prolongation ("Sssssun")',
                  sinhalaTitle: 'දිගු කිරීම',
                  count: prolongations,
                  color: const Color(0xFF8B5CF6),
                  isPrimary: primaryStutteringType.toLowerCase().contains('prolong'),
                ),
                _CategoryRow(
                  title: 'Block (Getting stuck)',
                  sinhalaTitle: 'අවහිරවීම්',
                  count: blocks,
                  color: AppColors.coralRed,
                  isPrimary: primaryStutteringType.toLowerCase().contains('block'),
                ),
                _CategoryRow(
                  title: 'Word Repetition ("I-I-I want it")',
                  sinhalaTitle: 'වචන පුනරාවර්තනය',
                  count: wordRepetitions,
                  color: AppColors.ctaOrange,
                  isPrimary: primaryStutteringType.toLowerCase().contains('word'),
                ),
                _CategoryRow(
                  title: 'Interjection ("Umm, I want it")',
                  sinhalaTitle: 'අතුරු වදන් / පිරවුම්',
                  count: interjections,
                  color: const Color(0xFF14B8A6),
                  isPrimary: primaryStutteringType.toLowerCase().contains('interjection'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stuttering Event Timeline with fl_chart
          _buildTimelineChart(),

          const SizedBox(height: 24),

          // Shared Results with C2, C3, and C4 (PDF Page 6)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF0066CC).withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_rounded, color: Color(0xFF0066CC), size: 22),
                    SizedBox(width: 8),
                    Text('Next Steps in Swara System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('ප්‍රතිඵල අනෙකුත් අංග සමඟ බෙදාගැනීම (C2, C3, C4)', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 16),

                _ActionTile(
                  icon: Icons.videocam_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Component 2: Video Analysis',
                  subtitle: 'Examine secondary facial/physical concomitant behaviors',
                  buttonText: 'Start C2 Video Analysis',
                  onTap: () => context.push('/c2/upload'),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.park_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Component 3: Guided Therapy',
                  subtitle: 'Adaptive LinUCB activities customized to $severity severity',
                  buttonText: 'Start Recommended Therapy',
                  onTap: () => context.push('/c3/forest-therapy'),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.record_voice_over_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Component 4: Language & Topic Practice',
                  subtitle: 'Explore conversational topics and personalized interests',
                  buttonText: 'Go to Component 4',
                  onTap: () => context.push('/c4'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Clinical Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text('AI Research Assessment Prototype', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                SizedBox(height: 6),
                Text(
                  'These automated results are research approximations inspired by SSI-4 and must be interpreted by a certified Speech-Language Pathologist (SLP).',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryDeep, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Back to Home', style: TextStyle(fontSize: 16, color: AppColors.primaryDeep, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getColorForEventType(String eventType) {
    final t = eventType.toLowerCase();
    if (t.contains('sound')) return const Color(0xFFF59E0B); // Amber
    if (t.contains('word')) return AppColors.ctaOrange;      // Orange
    if (t.contains('prolong')) return const Color(0xFF8B5CF6); // Purple
    if (t.contains('block')) return AppColors.coralRed;        // Red
    if (t.contains('interjection')) return const Color(0xFF14B8A6); // Teal
    return AppColors.mintGreen;
  }

  Widget _buildTimelineChart() {
    final events = detectedEvents;

    List<BarChartGroupData> barGroups = [];
    if (events.isNotEmpty) {
      for (int i = 0; i < events.length; i++) {
        final ev = events[i];
        final start = ((ev is Map ? (ev['startTime'] ?? ev['start_time']) : 0) as num?)?.toDouble() ?? 0.0;
        final dur = ((ev is Map ? (ev['duration'] ?? 1.0) : 1.0) as num?)?.toDouble() ?? 1.0;
        final evType = (ev is Map ? (ev['eventType'] ?? ev['event_type']) : '') as String;

        barGroups.add(
          BarChartGroupData(
            x: start.toInt(),
            barRods: [
              BarChartRodData(
                toY: math.min(5.0, math.max(0.6, dur)),
                color: _getColorForEventType(evType),
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
      padding: const EdgeInsets.all(22),
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
            'කථන අවහිරතා කාලරේඛාව (කාලය හා කාල පරාසය)',
            style: TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),

          // Visual Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendDot('Sound Rep', const Color(0xFFF59E0B)),
              _legendDot('Prolongation', const Color(0xFF8B5CF6)),
              _legendDot('Block', AppColors.coralRed),
              _legendDot('Word Rep', AppColors.ctaOrange),
              _legendDot('Interjection', const Color(0xFF14B8A6)),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 5,
                minY: 0,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                : '${events.length} event(s) mapped across ${_formatTime(widget.durationSeconds)}. Height represents event duration.',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
      ],
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

class _CategoryRow extends StatelessWidget {
  final String title;
  final String sinhalaTitle;
  final int count;
  final Color color;
  final bool isPrimary;

  const _CategoryRow({
    required this.title,
    required this.sinhalaTitle,
    required this.count,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPrimary ? color.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? color : AppColors.divider,
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  sinhalaTitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
