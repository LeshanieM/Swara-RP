part of '../../therapy_ui.dart';

class _Progress extends StatefulWidget {
  const _Progress();

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  int _completedActivities = 1;
  double _score = 8.5;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final model = await _LinUcbModel.load();
      if (mounted) {
        setState(() {
          _completedActivities = model.sessionActivitiesCompleted > 0
              ? model.sessionActivitiesCompleted
              : 1;
          _score = model.sessionScoreOutOfTen > 0 ? model.sessionScoreOutOfTen : 8.5;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    final progressFraction = (_completedActivities / 5.0).clamp(0.2, 1.0);

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackHeader(title: ''),
            const Center(
              child: Text(
                'ඔබේ සාරාංශය',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _C.darkText,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Center(
              child: Text(
                'ඔබ සම්පූර්ණ කළ ක්‍රියාකාරකම්',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            Center(
              child: Text(
                theme.journeyName,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'සම්පූර්ණ කළ ක්‍රියාකාරකම්',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_completedActivities / 5',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _C.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: Colors.blue.shade50,
                    color: theme.accentColor,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${_score.toStringAsFixed(1)} / 10',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _C.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ඔබේ ජයග්‍රහණ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ABadge(emoji: '🥇', label: 'පළමු පියවර'),
                _ABadge(emoji: '🗣️', label: 'දක්ෂ කථිකයා'),
                _ABadge(emoji: '🌟', label: 'ගවේෂකයා'),
              ],
            ),
            const SizedBox(height: 24),
            _Btn(
              text: 'ගමන් සිතියම බලන්න',
              onTap: () => nav?.go(_TherapyRoute.journeyMap),
            ),
            const SizedBox(height: 12),
            _Btn(
              text: 'මුල් පිටුවට යන්න',
              onTap: () => nav?.go(_TherapyRoute.home),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ABadge extends StatelessWidget {
  final String emoji, label;
  const _ABadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _C.chipBg,
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _C.darkText,
          ),
        ),
      ]);
}
