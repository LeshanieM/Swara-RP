part of '../../therapy_ui.dart';

/// The parent's 6-item questionnaire after a live session (1–5 each). It needs parent
/// mode, and the API adds it to the session's Therapy Success Score.
class _Questionnaire extends ConsumerStatefulWidget {
  const _Questionnaire();

  @override
  ConsumerState<_Questionnaire> createState() => _QuestionnaireState();
}

class _QuestionnaireState extends ConsumerState<_Questionnaire> {
  List<Map<String, dynamic>> _items = const [];
  List<String> _labels = const [];
  final Map<String, int> _answers = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final q = await TherapyApiService.questionnaire();
      if (!mounted) return;
      setState(() {
        _items = [for (final i in (q['items'] as List? ?? const [])) Map<String, dynamic>.from(i as Map)];
        _labels = [for (final l in (q['scale']?['labels']?['si'] as List? ?? const [])) l.toString()];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(error).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_answers.length < _items.length || _isSaving) return;
    if (!await ensureParentMode(context, ref) || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final before = _C3Session.outcome?['tss'];
      final res = await TherapyApiService.submitQuestionnaire(_C3Session.sessionId!, _answers);
      if (res['outcome'] is Map) _C3Session.outcome = Map<String, dynamic>.from(res['outcome'] as Map);
      if (!mounted) return;
      // The parent's answers are the Q part of the Therapy Success Score: show how they changed it.
      final after = _C3Session.outcome?['tss'];
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Therapy Success Score'),
          content: Text(
            before == null || after == null
                ? 'Saved. Thank you!'
                : 'Before your answers: $before / 100\nWith your answers: $after / 100\n\n'
                    'TSS = 50% how the activities went + 30% engagement + 20% your answers.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      _InheritedNav.of(context)?.go(_TherapyRoute.progress);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiException.from(error).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _BackHeader(title: 'දෙමාපිය ප්‍රශ්න'),
          const Text(
            'For the parent: how was today\'s session?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(36), child: CircularProgressIndicator()))
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _load)
          else ...[
            for (final item in _items) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['text']?['si'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _C.darkText)),
                  Text(item['text']?['en'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (var v = 1; v <= 5; v++)
                      ChoiceChip(
                        label: Text(_labels.length >= v ? '$v · ${_labels[v - 1]}' : '$v'),
                        selected: _answers[item['id']] == v,
                        onSelected: (_) => setState(() => _answers[item['id'] as String] = v),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            _Btn(
              text: _isSaving
                  ? 'Saving...'
                  : (_answers.length < _items.length ? 'Answer all ${_items.length} questions' : 'යවන්න'),
              onTap: _submit,
            ),
          ],
          TextButton(
            onPressed: _isSaving ? null : () => _InheritedNav.of(context)?.go(_TherapyRoute.progress),
            child: const Text('Skip for now', style: TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
