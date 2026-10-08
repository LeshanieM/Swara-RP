part of '../../therapy_ui.dart';

class _SessionComplete extends StatefulWidget {
  const _SessionComplete();

  @override
  State<_SessionComplete> createState() => _SessionCompleteState();
}

class _SessionCompleteState extends State<_SessionComplete> {
  _LinUcbModel? _model;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSessionSummary();
  }

  Future<void> _loadSessionSummary() async {
    try {
      final model = await _LinUcbModel.load();
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

  Future<void> _saveAndContinue() async {
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

    final completed = model.sessionActivitiesCompleted;
    final saved = await TherapyApiService.completeActiveSession(
      resultSummary: {
        'activitiesCompleted': completed,
        'activitiesTotal': completed,
        'score': model.sessionScoreOutOfTen,
        'scoreOutOf': 10,
        'durationMinutes': model.sessionDurationMinutes,
      },
    );
    if (!mounted) return;
    if (!saved) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this therapy result. Try again.'),
        ),
      );
      return;
    }
    _InheritedNav.of(context)?.go(_TherapyRoute.progress);
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
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
        else if (model == null)
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
                value: '${model.sessionActivitiesCompleted}',
                emoji: '🧩',
              ),
              _StCard(
                label: 'Feedback',
                value: '${model.sessionScoreOutOfTen.toStringAsFixed(1)} / 10',
                emoji: '⭐️',
              ),
              _StCard(
                label: 'Time',
                value: '${model.sessionDurationMinutes} min',
                emoji: '⏱️',
              ),
            ],
          ),
        const SizedBox(height: 24),
        _Btn(
            text: _isSaving ? 'Saving...' : 'සාරාංශය බලන්න',
            onTap: _isSaving || model == null || _error != null
                ? () {}
                : _saveAndContinue),
        const SizedBox(height: 20),
      ]),
    ));
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
