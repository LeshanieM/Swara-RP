part of '../../therapy_ui.dart';

class _Feedback extends StatefulWidget {
  const _Feedback();

  @override
  State<_Feedback> createState() => _FeedbackState();
}

class _FeedbackState extends State<_Feedback> {
  int _rating = 4;
  String _difficulty = 'just_right';
  int _helpLevel = 1;
  final Set<String> _selectedTags = {'විශ්වාසයෙන් කතා කළා'};
  bool _isSaving = false;

  static const _tags = [
    'විශ්වාසයෙන් කතා කළා (Spoke confidently)',
    'සන්සුන්ව හුස්ම ගත්තා (Calm breathing)',
    'සුමට උච්චාරණය (Smooth pronunciation)',
    'හොඳ අවධානය (Good focus)',
  ];

  Future<void> _submitFeedback() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final reward = _difficulty == 'just_right'
        ? 1.0
        : (_difficulty == 'too_easy' ? 0.6 : 0.35);

    try {
      final model = await _LinUcbModel.load();
      if (model.pendingActivityId != null) {
        await model.recordPendingReward(0.6 * (_rating / 5.0) + 0.4 * reward);
      }
    } catch (_) {}

    // Submit questionnaire answers based on parent's live input
    try {
      await TherapyApiService.submitParentQuestionnaire(
        responses: {
          'Q1': _rating,
          'Q2': _difficulty == 'just_right' ? 5 : (_difficulty == 'too_easy' ? 3 : 2),
          'Q3': _rating >= 3 ? 5 : 3,
          'Q4': 5 - _helpLevel,
          'Q5': _rating,
        },
      );
    } catch (e) {
      debugPrint('Feedback submission error: $e');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    _InheritedNav.of(context)?.go(_TherapyRoute.adaptiveConversation);
  }

  String get _ratingLabel {
    switch (_rating) {
      case 5:
        return 'ඉතා විශිෂ්ටයි! (Excellent)';
      case 4:
        return 'ඉතා හොඳයි! (Very Good)';
      case 3:
        return 'හොඳයි (Good)';
      case 2:
        return 'තව පුහුණුව අවශ්‍යයි (Needs Practice)';
      default:
        return 'උත්සාහ කළා (Attempted)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const Text(
              'දෙමාපියන්ගේ ඇගයීම',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Parent Activity Rating & Feedback',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const _Mascot(size: 110),
            const SizedBox(height: 14),

            // Star Rating Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  const Text(
                    'දරුවාගේ කථන චතුරතාවය (Fluency Rating)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.darkText),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _C.gold,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ratingLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.blue),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_rating * 2} / 10 Fluency Score',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _C.blue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Difficulty Selection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ක්‍රියාකාරකමේ අපහසුතාව (Difficulty):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.darkText),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'key': 'too_hard', 'label': 'ඉතා අපහසුයි', 'emoji': '😟'},
                      {'key': 'just_right', 'label': 'හරියටම හරි', 'emoji': '🙂'},
                      {'key': 'too_easy', 'label': 'ඉතා පහසුයි', 'emoji': '😊'},
                    ].map((opt) {
                      final isSelected = _difficulty == opt['key'];
                      return ChoiceChip(
                        avatar: Text(opt['emoji']!),
                        label: Text(opt['label']!),
                        selected: isSelected,
                        selectedColor: _C.blue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : _C.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _difficulty = opt['key']!),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Parent Help Level
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ඔබෙන් අවශ්‍ය වූ සහය (Assistance Provided):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.darkText),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      {'level': 0, 'label': 'නැත (None)'},
                      {'level': 1, 'label': 'සුළු සහයක් (Minimal)'},
                      {'level': 2, 'label': 'මධ්‍යස්ථ (Moderate)'},
                      {'level': 3, 'label': 'වැඩි සහයක් (Full)'},
                    ].map((h) {
                      final isSelected = _helpLevel == h['level'];
                      return ChoiceChip(
                        label: Text(h['label'] as String),
                        selected: isSelected,
                        selectedColor: _C.blue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : _C.darkText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _helpLevel = h['level'] as int),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick Observation Tags
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'නිරීක්ෂණ (Observations):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.darkText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag.split(' (')[0]),
                        selected: isSelected,
                        selectedColor: _C.blue.withValues(alpha: 0.2),
                        checkmarkColor: _C.blue,
                        labelStyle: TextStyle(
                          color: isSelected ? _C.blue : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setState(() {
                          if (val) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _Btn(
              text: _isSaving ? 'සුරකිමින්...' : 'ඇගයීම සුරකින්න (Submit Rating)',
              onTap: _submitFeedback,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => nav?.go(_TherapyRoute.adaptiveConversation),
              child: const Text('මඟහැර ඉදිරියට යන්න (Skip)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
