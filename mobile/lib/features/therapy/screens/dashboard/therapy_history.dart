part of '../../therapy_ui.dart';

class _TherapyHistory extends StatefulWidget {
  const _TherapyHistory();
  @override
  State<_TherapyHistory> createState() => _TherapyHistoryState();
}

class _TherapyHistoryState extends State<_TherapyHistory> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Ideally we get childId from Riverpod authProvider, here we mock 'child_1' or use a fixed ID for now.
    final history = await TherapyApiService.getTherapyHistory('child_1');
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
      paintScene: false,
      child: Column(children: [
        const _BackHeader(title: 'ප්‍රතිකාර ඉතිහාසය'),
        Expanded(child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.blue, Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(children: [
                const Text('සමස්ත ප්‍රගතිය', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _HistoryStat(label: 'Sessions', value: '${_history.length}', icon: '🗓️'),
                  const _HistoryStat(label: 'Streak', value: '5 Days', icon: '🔥'),
                  const _HistoryStat(label: 'Stars', value: '1.2k', icon: '⭐'),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => nav?.go(18),
              icon: const Icon(Icons.insights_rounded),
              label: const Text('දරුවාගේ සහභාගීත්වය බලන්න'),
              style: OutlinedButton.styleFrom(foregroundColor: _C.blue, side: const BorderSide(color: _C.blue), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 24),
            const Text('මෑත සැසි', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.darkText)),
            const SizedBox(height: 16),
            if (_history.isEmpty)
              const Center(child: Text('No history found.', style: TextStyle(color: Colors.grey))),
            ..._history.map((session) {
              final date = session['createdAt'] != null ? DateTime.parse(session['createdAt']).toLocal().toString().substring(0, 16) : 'Unknown Date';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HistoryCard(
                  date: date, 
                  theme: 'Session ${session['sessionId']}', 
                  score: session['status'] ?? 'Unknown', 
                  activities: (session['selectedActivities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Unknown Activity']
                ),
              );
            }).toList(),
            const SizedBox(height: 30),
          ]),
        )),
      ]),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _HistoryStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 24)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);
}

class _HistoryCard extends StatelessWidget {
  final String date;
  final String theme;
  final String score;
  final List<String> activities;
  final bool isRecent;
  final bool hasBadge;
  const _HistoryCard({required this.date, required this.theme, required this.score, required this.activities, this.isRecent = false, this.hasBadge = false});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), border: Border.all(color: isRecent ? _C.blue.withValues(alpha: 0.5) : Colors.transparent, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isRecent ? _C.blue.withValues(alpha: 0.1) : const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(Icons.calendar_today_rounded, size: 14, color: isRecent ? _C.blue : Colors.grey.shade600), const SizedBox(width: 6), Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isRecent ? _C.blue : _C.darkText))]),
          if (hasBadge) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _C.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Text('🏆 Top Score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Adventure: $theme', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _C.darkText)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: activities.map((activity) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(activity, style: const TextStyle(fontSize: 11, color: Colors.black54)))).toList()),
          ])),
          const SizedBox(width: 12),
          Column(children: [const Text('Score', style: TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text(score, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.green)))]),
        ]),
      ),
    ]),
  );
}
