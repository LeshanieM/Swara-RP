part of '../../therapy_ui.dart';

class _BanditReasoning extends StatelessWidget {
  const _BanditReasoning();

  static const _arms = [
    {'name': 'Story reading', 'score': 0.71, 'picked': true},
    {'name': 'Syllable practice', 'score': 0.52, 'picked': false},
    {'name': 'Breathing exercise', 'score': 0.38, 'picked': false},
    {'name': 'Conversation prompt', 'score': 0.47, 'picked': false},
    {'name': 'DAF-lite', 'score': 0.21, 'picked': false},
  ];

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
        paintScene: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _BackHeader(title: ''),
            const Center(
                child: Text('Why this activity?',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _C.darkText))),
            const SizedBox(height: 4),
            const Center(
                child: Text('Contextual bandit decision for this session',
                    style: TextStyle(fontSize: 12, color: Colors.black54))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ]),
              child: const Wrap(spacing: 8, runSpacing: 8, children: [
                _CtxChip(label: 'Severity: Moderate'),
                _CtxChip(label: 'Age: 8'),
                _CtxChip(label: 'Concomitants: Low'),
                _CtxChip(label: 'Engagement (last session): 0.74'),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('Arm scores',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText)),
            const SizedBox(height: 10),
            ..._arms.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(a['name'] as String,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: (a['picked'] as bool)
                                          ? _C.blue
                                          : _C.darkText)),
                              Text((a['score'] as double).toStringAsFixed(2),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ]),
                        const SizedBox(height: 4),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: a['score'] as double,
                              minHeight: 12,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: (a['picked'] as bool)
                                  ? _C.blue
                                  : Colors.grey.shade400,
                            )),
                      ]),
                )),
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(14)),
                child: const Text(
                    'Story reading scored highest given low concomitants and strong engagement last session — the therapist knowledge base allowed it, so it was selected.',
                    style: TextStyle(
                        fontSize: 12, color: _C.darkText, height: 1.4))),
            const SizedBox(height: 20),
            _Btn(
                text: 'See Guardrails →',
                onTap: () => nav?.go(_TherapyRoute.therapistKnowledgeBase)),
            const SizedBox(height: 20),
          ]),
        ));
  }
}

class _CtxChip extends StatelessWidget {
  final String label;
  const _CtxChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
      );
}

// ----------------------------------------------------------------------------
// 23. THERAPIST KNOWLEDGE BASE — Pillar 3, SLP-authored guardrails visible
// ----------------------------------------------------------------------------
