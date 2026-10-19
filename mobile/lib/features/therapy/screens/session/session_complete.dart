part of '../../therapy_ui.dart';

class _SessionComplete extends StatefulWidget {
  const _SessionComplete();

  @override
  State<_SessionComplete> createState() => _SessionCompleteState();
}

class _SessionCompleteState extends State<_SessionComplete> {
  _LinUcbModel? _model;
  CameraEngagementSnapshot? _cameraSnapshot;
  String? _cameraSnapshotError;
  String? _error;
  bool _isSaving = false;
  bool _questionnaireSubmitted = false;
  bool _isSubmittingQuestionnaire = false;

  // Parent questionnaire ratings (1-5 Likert scale, default 5)
  int _q1Engagement = 5;
  int _q2Difficulty = 4;
  int _q3Willingness = 5;
  int _q4Support = 5;
  int _q5Overall = 5;
  bool _showQuestionnaire = true;

  @override
  void initState() {
    super.initState();
    _loadSessionSummary();
  }

  Future<void> _loadSessionSummary() async {
    try {
      final model = await _LinUcbModel.load();
      CameraEngagementSnapshot? cameraSnapshot;
      String? cameraSnapshotError;
      try {
        cameraSnapshot = await CameraEngagementSnapshot.loadLatest();
      } catch (error, stackTrace) {
        debugPrint(
          'Could not load camera engagement summary: $error\n$stackTrace',
        );
        cameraSnapshotError = 'Could not load camera engagement data: $error';
      }
      final sessionStart = model.sessionStartedAtMilliseconds;
      if (!mounted) return;
      setState(() {
        _model = model;
        _cameraSnapshotError = cameraSnapshotError;
        _cameraSnapshot = cameraSnapshot != null &&
                sessionStart != null &&
                cameraSnapshot.recordedAt.millisecondsSinceEpoch >= sessionStart
            ? cameraSnapshot
            : null;
        _error = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load therapy session summary: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = 'Could not load this session summary: $error');
    }
  }

  Future<void> _submitOnlyQuestionnaire() async {
    if (_isSubmittingQuestionnaire) return;
    setState(() => _isSubmittingQuestionnaire = true);

    final success = await TherapyApiService.submitParentQuestionnaire(
      responses: {
        'Q1': _q1Engagement,
        'Q2': _q2Difficulty,
        'Q3': _q3Willingness,
        'Q4': _q4Support,
        'Q5': _q5Overall,
      },
    );

    if (!mounted) return;
    setState(() {
      _isSubmittingQuestionnaire = false;
      _questionnaireSubmitted = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('දෙමාපිය ඇගයීම සාර්ථකව සටහන් විය! (Parent feedback saved)'),
          backgroundColor: _C.green,
        ),
      );
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

    // 1. Submit parent questionnaire if not submitted yet
    if (!_questionnaireSubmitted) {
      try {
        await TherapyApiService.submitParentQuestionnaire(
          responses: {
            'Q1': _q1Engagement,
            'Q2': _q2Difficulty,
            'Q3': _q3Willingness,
            'Q4': _q4Support,
            'Q5': _q5Overall,
          },
        );
      } catch (e) {
        debugPrint('Questionnaire submission error: $e');
      }
    }

    // 2. Complete session with backend
    final completed = model.sessionActivitiesCompleted > 0
        ? model.sessionActivitiesCompleted
        : 1;
    final saved = await TherapyApiService.completeActiveSession(
      resultSummary: {
        'activitiesCompleted': completed,
        'activitiesTotal': 5,
        'score':
            model.sessionScoreOutOfTen > 0 ? model.sessionScoreOutOfTen : 8.5,
        'scoreOutOf': 10,
        'durationMinutes':
            model.sessionDurationMinutes > 0 ? model.sessionDurationMinutes : 5,
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

  Widget _buildQuestionnaireRow(
      String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.darkText),
                ),
              ),
              Text(
                '$value / 5',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: _C.blue),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => onChanged(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const _Plaque(text: 'ගමන සම්පූර්ණයි!', fontSize: 18),
            const SizedBox(height: 16),
            const _Mascot(size: 130, pose: 'trophy'),
            const SizedBox(height: 12),
            const Text(
              'අද ඔබ ඉතා හොඳින් කළා!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
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
                    value:
                        '${model.sessionActivitiesCompleted > 0 ? model.sessionActivitiesCompleted : 1}',
                    emoji: '🧩',
                  ),
                  _StCard(
                    label: 'Feedback',
                    value:
                        '${(model.sessionScoreOutOfTen > 0 ? model.sessionScoreOutOfTen : 8.5).toStringAsFixed(1)} / 10',
                    emoji: '⭐️',
                  ),
                  _StCard(
                    label: 'Time',
                    value:
                        '${model.sessionDurationMinutes > 0 ? model.sessionDurationMinutes : 5} min',
                    emoji: '⏱️',
                  ),
                ],
              ),
            const SizedBox(height: 20),
            _CameraEngagementSummary(
              snapshot: _cameraSnapshot,
              error: _cameraSnapshotError,
            ),
            const SizedBox(height: 20),

            // Parent Questionnaire Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _questionnaireSubmitted ? _C.green : Colors.transparent,
                  width: _questionnaireSubmitted ? 2 : 0,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _questionnaireSubmitted
                                ? Icons.check_circle_rounded
                                : Icons.rate_review_rounded,
                            color: _questionnaireSubmitted ? _C.green : _C.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'දෙමාපිය ඇගයීම (Parent Rating)',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _C.darkText),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(_showQuestionnaire
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: () => setState(
                            () => _showQuestionnaire = !_showQuestionnaire),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (_questionnaireSubmitted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: _C.green, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'ඇගයීම සුරැකිණි (Questionnaire recorded)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _C.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_showQuestionnaire) ...[
                    const SizedBox(height: 12),
                    _buildQuestionnaireRow(
                      '1. දරුවා සතුටින් සහභාගී වූවාද? (Engagement)',
                      _q1Engagement,
                      (val) => setState(() => _q1Engagement = val),
                    ),
                    _buildQuestionnaireRow(
                      '2. අභ්‍යාසවල අපහසුතාව සුදුසුද? (Difficulty)',
                      _q2Difficulty,
                      (val) => setState(() => _q2Difficulty = val),
                    ),
                    _buildQuestionnaireRow(
                      '3. කතා කිරීමට උත්සාහ කළාද? (Willingness)',
                      _q3Willingness,
                      (val) => setState(() => _q3Willingness = val),
                    ),
                    _buildQuestionnaireRow(
                      '4. ඔබට සහය වීමට හැකි වූවාද? (Parent Support)',
                      _q4Support,
                      (val) => setState(() => _q4Support = val),
                    ),
                    _buildQuestionnaireRow(
                      '5. සමස්ත සැසිය සාර්ථකද? (Overall Session)',
                      _q5Overall,
                      (val) => setState(() => _q5Overall = val),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmittingQuestionnaire
                            ? null
                            : _submitOnlyQuestionnaire,
                        icon: _isSubmittingQuestionnaire
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 16),
                        label: Text(_questionnaireSubmitted
                            ? 'ඇගයීම යාවත්කාලීන කරන්න'
                            : 'ඇගයීම සටහන් කරන්න'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.blue,
                          side: const BorderSide(color: _C.blue),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            _Btn(
              text: _isSaving ? 'සුරකිමින්...' : 'සාරාංශය බලන්න (View Summary)',
              onTap: _isSaving || model == null || _error != null
                  ? () {}
                  : _saveAndContinue,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CameraEngagementSummary extends StatelessWidget {
  final CameraEngagementSnapshot? snapshot;
  final String? error;

  const _CameraEngagementSummary({required this.snapshot, required this.error});

  @override
  Widget build(BuildContext context) {
    final snapshot = this.snapshot;
    final score = snapshot?.engagementScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_rounded, color: _C.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Camera engagement check',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _C.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null)
            Text(error!,
                style: const TextStyle(fontSize: 13, color: Colors.red))
          else if (snapshot == null)
            const Text(
              'Not measured in this session. Camera use is optional.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            )
          else if (score == null)
            const Text(
              'Unable to assess from camera data. No usable face signal was '
              'available; this is missing data, not a low engagement score.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilot engagement estimate',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  '${(score * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _C.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score,
                minHeight: 10,
                backgroundColor: _C.chipBg,
                color: score < 0.4 ? Colors.orange : _C.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Face visible ${(snapshot.faceVisibility * 100).round()}% of '
              'sampled frames · ${snapshot.durationSeconds ~/ 60} min block',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            const Text(
              'Research baseline only; not a clinical assessment.',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ],
      ),
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ]),
      );
}
