part of '../../therapy_ui.dart';

class _SessionComplete extends StatefulWidget {
  const _SessionComplete();

  @override
  State<_SessionComplete> createState() => _SessionCompleteState();
}

class _SessionCompleteState extends State<_SessionComplete> {
  _DemoPlan? _model;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSessionSummary();
  }

  Future<void> _loadSessionSummary() async {
    if (_C3Session.isLive) return _completeLive();
    try {
      final model = await _DemoPlan.load();
      if (!mounted) return;
      setState(() {
        _model = model;
        _error = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load therapy session summary: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = 'Could not load this session summary: $error');
    }
  }

  /// Closes the session on the API (an open activity is marked abandoned) and shows its outcome.
  Future<void> _completeLive() async {
    try {
      if (_C3Session.outcome == null) await _C3Session.complete();
      if (!mounted) return;
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiException.from(error).message);
    }
  }

  Future<void> _saveAndContinue() async {
    if (_C3Session.isLive) {
      // The parent questionnaire adds the Q part of the TSS.
      _InheritedNav.of(context)?.go(_TherapyRoute.questionnaire);
      return;
    }
    final model = _model;
    if (model == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await model.clearPendingWithoutReward();
    } catch (error, stackTrace) {
      debugPrint('Could not clear unfinished activity: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the session summary: $error')),
      );
      return;
    }

    _InheritedNav.of(context)?.go(_TherapyRoute.progress);
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    final outcome = _C3Session.outcome;
    final started = _C3Session.sessionStartedAt;
    // The three tiles: activities, score and time, from the API outcome or the on-device model.
    final (String, String, String, String)? tiles = _C3Session.isLive
        ? outcome == null
            ? null
            : (
                '${outcome['activitiesCompleted'] ?? 0}',
                'Therapy Success Score',
                outcome['tss'] == null ? '—' : '${outcome['tss']} / 100',
                '${started == null ? 0 : DateTime.now().difference(started).inMinutes} min',
              )
        : model == null
            ? null
            : (
                '${model.sessionActivitiesCompleted}',
                'Therapy Success Score (demo)',
                '${(model.sessionScoreOutOfTen * 10).toStringAsFixed(0)} / 100',
                '${model.sessionDurationMinutes} min',
              );
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const _Plaque(text: 'ගමන සම්පූර්ණයි!', fontSize: 18),
        const SizedBox(height: 16),
        const _Mascot(size: 160, pose: 'trophy'),
        const SizedBox(height: 12),
        const Text('අද ඔබ ඉතා හොඳින් කළා!',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        if (_error != null)
          Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: _loadSessionSummary,
                child: const Text('Try again'),
              ),
            ],
          )
        else if (tiles == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StCard(
                label: 'Activities',
                value: tiles.$1,
                emoji: '🧩',
              ),
              _StCard(
                label: tiles.$2,
                value: tiles.$3,
                emoji: '⭐️',
              ),
              _StCard(
                label: 'Time',
                value: tiles.$4,
                emoji: '⏱️',
              ),
            ],
          ),
        if (_error == null && outcome?['meanEngagement'] is num) ...[
          const SizedBox(height: 16),
          _EngagementMeter(outcome: outcome!),
        ],
        const SizedBox(height: 24),
        _Btn(
            text: _isSaving ? 'Saving...' : 'සාරාංශය බලන්න',
            onTap: _isSaving || tiles == null || _error != null
                ? () {}
                : _saveAndContinue),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

/// The session's mean engagement E, and what it was measured from (camera and activity, or activity only).
class _EngagementMeter extends StatelessWidget {
  final Map<String, dynamic> outcome;
  const _EngagementMeter({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final e = (outcome['meanEngagement'] as num).toDouble().clamp(0.0, 1.0);
    final modes = outcome['engagementModes'] is Map
        ? outcome['engagementModes'] as Map
        : const {};
    final source =
        (modes['camera_logs'] ?? 0) > 0 ? 'Camera + activity' : 'Activity only';
    final (label, color) = e < 0.4
        ? ('Low', Colors.orange.shade700)
        : e < 0.7
            ? ('Medium', Colors.amber.shade700)
            : ('High', _C.green);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Expanded(
              child: Text('අවධානය · Engagement',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _C.darkText))),
          Text('${(e * 100).round()}% · $label',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: e,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.grey.shade200),
        ),
        const SizedBox(height: 6),
        Text(source, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }
}

class _StCard extends StatelessWidget {
  final String label, value, emoji;
  const _StCard(
      {required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) => Container(
        width: 95,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _C.darkText)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      );
}

// 13. PROGRESS
