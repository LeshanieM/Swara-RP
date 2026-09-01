part of '../swara_therapy_ui.dart';

class _S24Engagement extends StatelessWidget {
  const _S24Engagement();

  static const _history = [0.55, 0.6, 0.58, 0.65, 0.7, 0.68, 0.72, 0.75, 0.7, 0.74, 0.72, 0.78];

  @override
  Widget build(BuildContext context) {
    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _BackHeader(title: ''),
          const Center(child: Text('අද ඔබේ ප්‍රගතිය 🌟', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _C.darkText))),
          const SizedBox(height: 4),
          const Center(child: Text('ඔබ අද කොච්චර හොඳින් පුහුණු වුණාද බලමු!', style: TextStyle(fontSize: 13, color: Colors.black54))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: const Column(children: [
              Text('8 / 10', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _C.blue)),
              Text('අද දින පුහුණුව', style: TextStyle(fontSize: 12, letterSpacing: 0.5, color: Colors.grey, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('නියමයි! ඔබ ඉතා උනන්දුවෙන් සහභාගී වුණා. 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _C.darkText)),
              SizedBox(height: 16),
              _CompRow(label: 'ක්‍රියාකාරකම් අවසන් කළා', value: 0.9),
              _CompRow(label: 'සෙමින් කතා කළා', value: 0.68),
              _CompRow(label: 'නැවත උත්සාහ කළා', value: 0.8),
              _CompRow(label: 'සතුටින් සහභාගී වුණා', value: 0.72),
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ඔබේ ප්‍රගතිය', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
              const SizedBox(height: 3),
              const Text('සැසියෙන් සැසියට ඔබ වැඩි දියුණු වෙමින් සිටී!', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 12),
              SizedBox(height: 70, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _history.map((value) => Expanded(
                child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: value * 70, decoration: BoxDecoration(color: _C.green, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
              )).toList())),
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('පළමු සැසිය', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('අද', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final double value;
  const _CompRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))),
      Expanded(flex: 4, child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), color: _C.blue))),
      const SizedBox(width: 8),
      Text('${(value * 10).round()}/10', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _S25TherapyHistory extends StatelessWidget {
  const _S25TherapyHistory();

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
      paintScene: false,
      child: Column(children: [
        const _BackHeader(title: 'ප්‍රතිකාර ඉතිහාසය'),
        Expanded(child: SingleChildScrollView(
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
                  _HistoryStat(label: 'Sessions', value: '14', icon: '🗓️'),
                  _HistoryStat(label: 'Streak', value: '5 Days', icon: '🔥'),
                  _HistoryStat(label: 'Stars', value: '1.2k', icon: '⭐'),
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
            const _HistoryCard(date: 'Today, 4:30 PM', theme: 'Magic Forest', score: '8 / 10', activities: ['Breathing', 'Syllable Practice', 'Picture Description'], isRecent: true),
            const SizedBox(height: 16),
            const _HistoryCard(date: 'Yesterday, 5:15 PM', theme: 'Deep Ocean', score: '7 / 10', activities: ['Breathing', 'Guided Conversation']),
            const SizedBox(height: 16),
            const _HistoryCard(date: 'Monday, 3:45 PM', theme: 'Space Adventure', score: '9 / 10', activities: ['Syllable Practice', 'Guided Conversation'], hasBadge: true),
            const SizedBox(height: 16),
            const _HistoryCard(date: 'Sunday, 10:00 AM', theme: 'Magic Forest', score: '6 / 10', activities: ['Breathing', 'Syllable Practice']),
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
