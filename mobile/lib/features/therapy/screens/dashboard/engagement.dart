part of '../../therapy_ui.dart';

class _Engagement extends StatefulWidget {
  const _Engagement();

  @override
  State<_Engagement> createState() => _EngagementState();
}

enum _EngagementRange { week, month }

class _EngagementState extends State<_Engagement> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  _EngagementRange _range = _EngagementRange.week;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (mounted) setState(() => _isLoading = true);
    final sessions = await TherapyApiService.getTherapyHistory();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _days => _range == _EngagementRange.week ? 7 : 30;

  List<_EngagementDay> get _daysInRange {
    final firstDay = _today.subtract(Duration(days: _days - 1));
    final days = List.generate(
      _days,
      (index) => _EngagementDay(firstDay.add(Duration(days: index))),
    );

    for (final session in _sessions) {
      if (session is! Map ||
          session['status']?.toString().toLowerCase() != 'completed') {
        continue;
      }
      final createdAt =
          DateTime.tryParse(session['createdAt']?.toString() ?? '');
      if (createdAt == null) continue;
      final localDate = createdAt.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final index = date.difference(firstDay).inDays;
      if (index < 0 || index >= days.length) continue;

      final summary = session['resultSummary'];
      if (summary is! Map) continue;
      final completed = _number(summary['activitiesCompleted']);
      final total = _number(summary['activitiesTotal']);
      final score = _number(summary['score']);
      final scoreOutOf = _number(summary['scoreOutOf']);
      final engagement = total > 0
          ? (completed / total).clamp(0.0, 1.0)
          : scoreOutOf > 0
              ? (score / scoreOutOf).clamp(0.0, 1.0)
              : null;
      if (engagement == null) continue;

      days[index].add(
        engagement,
        _number(summary['durationMinutes']).round(),
      );
    }
    return days;
  }

  double _number(dynamic value) => value is num ? value.toDouble() : 0;

  @override
  Widget build(BuildContext context) {
    final days = _daysInRange;
    final activeDays = days.where((day) => day.sessionCount > 0);
    final sessionCount =
        activeDays.fold<int>(0, (sum, day) => sum + day.sessionCount);
    final totalMinutes =
        activeDays.fold<int>(0, (sum, day) => sum + day.minutes);
    final engagementTotal = activeDays.fold<double>(
      0,
      (sum, day) => sum + day.engagementTotal,
    );
    final average = sessionCount == 0 ? 0.0 : engagementTotal / sessionCount;

    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _BackHeader(title: 'Therapy Progress'),
          const SizedBox(height: 12),
          SegmentedButton<_EngagementRange>(
            segments: const [
              ButtonSegment(
                  value: _EngagementRange.week, label: Text('පසුගිය සතිය')),
              ButtonSegment(
                  value: _EngagementRange.month, label: Text('පසුගිය මාසය')),
            ],
            selected: {_range},
            onSelectionChanged: (selection) =>
                setState(() => _range = selection.first),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _EngagementStat(
                  label: 'සාමාන්‍ය ක්‍රියාකාරකම් සම්පූර්ණය',
                  value: '${(average * 100).round()}%',
                ),
                _EngagementStat(label: 'සැසි', value: '$sessionCount'),
                _EngagementStat(
                  label: 'පුහුණු මිනිත්තු',
                  value: '$totalMinutes',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'දෛනික ප්‍රගතිය',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'සම්පූර්ණ කළ ක්‍රියාකාරකම් අනුව',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (sessionCount == 0)
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insights_outlined,
                              size: 34, color: Colors.black38),
                          const SizedBox(height: 8),
                          const Text(
                            'මෙම කාලසීමාව සඳහා සැසි දත්ත නැත',
                            style: TextStyle(color: Colors.black54),
                          ),
                          TextButton.icon(
                            onPressed: _loadSessions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('නැවත උත්සාහ කරන්න'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _EngagementBarChart(
                    days: days,
                    showDailyLabels: _range == _EngagementRange.week,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _EngagementDay {
  final DateTime date;
  int sessionCount = 0;
  int minutes = 0;
  double engagementTotal = 0;

  _EngagementDay(this.date);

  double get engagementPercent =>
      sessionCount == 0 ? 0 : engagementTotal / sessionCount * 100;

  void add(double engagement, int durationMinutes) {
    sessionCount++;
    engagementTotal += engagement;
    minutes += durationMinutes;
  }
}

class _EngagementBarChart extends StatelessWidget {
  final List<_EngagementDay> days;
  final bool showDailyLabels;

  const _EngagementBarChart({
    required this.days,
    required this.showDailyLabels,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 220,
        child: Column(children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: 34,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('100%',
                          style: TextStyle(fontSize: 9, color: Colors.black45)),
                      Text('50%',
                          style: TextStyle(fontSize: 9, color: Colors.black45)),
                      Text('0%',
                          style: TextStyle(fontSize: 9, color: Colors.black45)),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var line = 0; line < 3; line++)
                            const Divider(height: 1, color: Color(0xFFE8EDF0)),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final day in days)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: day.engagementPercent
                                            .clamp(0.0, 100.0) /
                                        100,
                                    widthFactor: 0.72,
                                    child: const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _C.green,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (showDailyLabels)
            Row(children: [
              const SizedBox(width: 34),
              for (final day in days)
                Expanded(
                  child: Text(
                    '${day.date.day}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: Colors.black45),
                  ),
                ),
            ])
          else
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${days.first.date.month}/${days.first.date.day}',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black45)),
                  Text('${days.last.date.month}/${days.last.date.day}',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black45)),
                ],
              ),
            ),
        ]),
      );
}

class _EngagementStat extends StatelessWidget {
  final String label;
  final String value;

  const _EngagementStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _C.blue)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]);
}
