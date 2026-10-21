part of 'therapy_ui.dart';

/// One activity the server chose (POST next-activity): the arm and its content item.
class _C3Attempt {
  final String attemptId;
  final String armId;
  final String type;
  final String difficulty;
  final String appActivityId;
  final bool parentLed;
  final String titleSi;
  final String titleEn;
  final String promptSi;
  final String promptEn;
  final int targets;

  /// Sinhala target words for word activities; each one is recorded and checked.
  final List<String> targetWords;

  /// The item's picture (picture naming / description), an asset path; may be a placeholder.
  final String? image;

  /// The passage to read (paragraph reading).
  final String textSi;
  final String textEn;

  /// Words a picture description should mention (checked by the server).
  final List<String> keywords;

  _C3Attempt.fromJson(Map<String, dynamic> json)
      : attemptId = json['attemptId'] as String,
        armId = json['activity']['armId'] as String,
        type = json['activity']['type'] as String,
        difficulty = json['activity']['difficulty'] as String? ?? '',
        appActivityId = json['activity']['appActivityId'] as String,
        parentLed = json['activity']['parentLed'] == true,
        titleSi = json['activity']['title']?['si'] ?? '',
        titleEn = json['activity']['title']?['en'] ?? '',
        promptSi = json['item']?['prompt']?['si'] ?? '',
        promptEn = json['item']?['prompt']?['en'] ?? '',
        targets = (json['item']?['targets'] as num?)?.toInt() ?? 1,
        targetWords = [
          for (final w
              in (json['item']?['targetWords']?['si'] as List? ?? const []))
            w.toString()
        ],
        image = json['item']?['image'] as String?,
        textSi = json['item']?['text']?['si'] ?? '',
        textEn = json['item']?['text']?['en'] ?? '',
        keywords = [
          for (final w
              in (json['item']?['keywords']?['si'] as List? ?? const []))
            w.toString()
        ];

  bool get isWordActivity => targetWords.isNotEmpty;
  bool get isPictureNaming => type == 'picture_naming';
  bool get isReading => type == 'passage_reading' && textSi.isNotEmpty;

  /// Reading and picture description: the whole recording is checked against the passage / keywords.
  bool get needsSpeechCheck =>
      isReading || (type == 'picture_description' && keywords.isNotEmpty);

  /// The prompts the activity screen steps through: one per target word, the passage, or the item's one prompt.
  List<String> get prompts => isWordActivity
      ? targetWords
      : isReading
          ? [textSi]
          : [promptEn.isEmpty ? promptSi : '$promptSi\n($promptEn)'];

  _TherapyActivityDefinition? get definition =>
      _therapyActivities.where((a) => a.id == appActivityId).firstOrNull;
}

/// What the child did in the activity, measured by the activity screen.
class _C3Progress {
  int promptsDone = 0;
  int recordings = 0;
  bool skipped = false;

  /// Touches on the screen during the activity.
  int taps = 0;

  /// Time from each prompt appearing to the child starting to record.
  final List<int> latenciesMs = [];
  DateTime? promptShownAt;
}

/// The live C3 session on the API. Demo mode never touches it and walks a fixed
/// activity order instead (`_DemoPlan`).
class _C3Session {
  static ChildRef? child;
  static String? sessionId;
  static _C3Attempt? current;
  static DateTime? startedAt;
  static _C3Progress progress = _C3Progress();

  /// Set when the activity screen finishes; the adaptive screen then asks for feedback and posts the result.
  static bool awaitingResult = false;
  static String advice = 'continue';
  static Map<String, dynamic>? outcome;

  /// Activities finished in this session and the session's limit (from the server's advice).
  static int activitiesDone = 0;
  static int maxActivities = 5;

  static void _readAdvice(Map<String, dynamic> res) {
    final a = res['advice'];
    if (a is! Map) return;
    advice = a['advice'] as String? ?? advice;
    activitiesDone = (a['activitiesDone'] as num?)?.toInt() ?? activitiesDone;
    maxActivities = (a['maxActivities'] as num?)?.toInt() ?? maxActivities;
  }

  static DateTime? sessionStartedAt;

  /// The parent allowed the camera for this session (and the phone supports it).
  static bool cameraOn = false;
  static Future<Map<String, Object?>?>? _cameraResult;

  static bool get isLive => !StorageService.isDemoMode();

  /// Whether the parent turned on camera engagement (off by default).
  static Future<bool> cameraAllowed() async =>
      EngagementCamera.isSupported &&
      (await StorageService.getBool(AppConstants.c3CameraEngagementKey) ??
          false);

  static bool get _inActivity =>
      current != null && startedAt != null && !awaitingResult;

  static Future<void> start() async {
    final c = child;
    if (c == null)
      throw const ApiException(
          'no_child', 'Choose a child on the therapist home first.');
    cameraOn = await cameraAllowed();
    final session = await TherapyApiService.startSession(
        childId: c.childId, age: c.age, cameraOn: cameraOn);
    sessionId = session['id'] as String;
    sessionStartedAt = DateTime.now();
    current = null;
    awaitingResult = false;
    advice = 'continue';
    outcome = null;
    activitiesDone = 0;
    maxActivities = (session['maxActivities'] as num?)?.toInt() ?? 5;
  }

  /// The session that can still be continued today (the server keeps it open for a few hours), or null.
  static Future<Map<String, dynamic>?> resumable() async {
    final c = child;
    if (!isLive || c == null) return null;
    final res = await TherapyApiService.activeSession(c.childId);
    return res['session'] is Map ? res : null;
  }

  /// Continues [active] (from [resumable]): the open activity, if any, is shown again.
  static Future<void> resume(Map<String, dynamic> active) async {
    final session = Map<String, dynamic>.from(active['session'] as Map);
    cameraOn = await cameraAllowed();
    sessionId = session['id'] as String;
    sessionStartedAt =
        DateTime.tryParse(session['createdAt']?.toString() ?? '')?.toLocal() ??
            DateTime.now();
    outcome = null;
    awaitingResult = false;
    _readAdvice(session);
    activitiesDone =
        (active['activitiesDone'] as num?)?.toInt() ?? activitiesDone;
    final pending = active['pending'];
    current = pending is Map
        ? _C3Attempt.fromJson(Map<String, dynamic>.from(pending))
        : null;
    progress = _C3Progress();
    startedAt = null;
  }

  /// Asks the server for the next activity. Returns null once the planned time is used.
  static Future<_C3Attempt?> next() async {
    final res = await TherapyApiService.nextActivity(sessionId!);
    _readAdvice(res);
    if (res['activity'] == null) return null;
    current = _C3Attempt.fromJson(res);
    progress = _C3Progress();
    startedAt = null;
    awaitingResult = false;
    return current;
  }

  /// The live attempt when it belongs to this screen's activity, otherwise null (demo mode, library browsing).
  static _C3Attempt? attemptFor(String appActivityId) =>
      isLive && current?.appActivityId == appActivityId && !awaitingResult
          ? current
          : null;

  /// A recording was made for prompt [promptIndex].
  static void recorded(int promptIndex) {
    progress.recordings++;
    if (promptIndex + 1 > progress.promptsDone)
      progress.promptsDone = promptIndex + 1;
    if (_inActivity)
      progress.promptShownAt =
          DateTime.now(); // the next prompt's wait starts now
  }

  /// The child started recording: the wait since the prompt appeared is one response latency.
  static void responded() {
    final shown = progress.promptShownAt;
    if (!_inActivity || shown == null) return;
    progress.latenciesMs.add(DateTime.now().difference(shown).inMilliseconds);
    progress.promptShownAt = null;
  }

  static void tapped() {
    if (_inActivity) progress.taps++;
  }

  /// Ends the live activity and returns to the adaptive screen for feedback and the next choice.
  static void finishAndContinue(BuildContext context,
      {bool skipped = false,
      String demoRoute = _TherapyRoute.adaptiveSyllable}) {
    if (isLive && current != null) {
      finish(skipped: skipped);
      _InheritedNav.of(context)?.go(_TherapyRoute.adaptiveSyllable);
      return;
    }
    _InheritedNav.of(context)?.go(demoRoute);
  }

  /// The activity screen calls this as the child starts.
  static void begin() {
    if (startedAt != null) return;
    startedAt = DateTime.now();
    progress.promptShownAt = startedAt;
    _cameraResult = null;
    if (cameraOn) EngagementCamera.instance.start();
  }

  /// The activity screen calls this when the child finishes (or skips) it.
  static void finish({bool skipped = false}) {
    if (current == null) return;
    progress.skipped = skipped;
    awaitingResult = true;
    if (cameraOn) _cameraResult = EngagementCamera.instance.stop();
  }

  /// Posts the finished activity; [feedback] is the "How did it feel?" tap, [parentHelp] the 0–3 parent-help tap.
  static Future<Map<String, dynamic>> postResult(
      {String? feedback, int? parentHelp}) async {
    final attempt = current!;
    final p = progress;
    final duration =
        DateTime.now().difference(startedAt ?? DateTime.now()).inSeconds;
    final shown = attempt.prompts.length;
    // Face numbers only (10-second windows); null when the camera was off or never saw a frame.
    final camera = cameraOn
        ? await (_cameraResult ?? EngagementCamera.instance.stop())
        : null;
    _cameraResult = null;
    final latencies = p.latenciesMs;
    final res =
        await TherapyApiService.postResult(sessionId!, attempt.attemptId, {
      'durationSec': duration < 1 ? 1 : duration,
      if (p.skipped)
        'skipped': true
      else ...{
        // Open-speech activities can't be scored on the phone: a recorded prompt counts as all its
        // targets. Word activities are scored on the server from the word checks.
        'targets': attempt.isWordActivity ? shown : attempt.targets,
        'successes': attempt.isWordActivity
            ? p.promptsDone.clamp(0, shown)
            : (p.recordings > 0 || attempt.type == 'breathing'
                ? attempt.targets
                : 0),
        'completedShare':
            shown == 0 ? 1 : (p.promptsDone / shown).clamp(0.0, 1.0),
      },
      'attempts': p.recordings,
      'earlyExit': !p.skipped && p.promptsDone < shown,
      'taps': p.taps,
      if (latencies.isNotEmpty)
        'responseLatencyMs':
            latencies.reduce((a, b) => a + b) / latencies.length,
      if (camera != null) 'camera': camera,
      if (feedback != null) 'parentFeedback': feedback,
      if (parentHelp != null) 'parentHelp': parentHelp,
    });
    _readAdvice(res);
    awaitingResult = false;
    current = null;
    return res;
  }

  /// Checks one recorded target word; returns a short message for the recording sheet.
  static Future<(String, Color)?> checkWord(
      RecordedAudio audio, int wordIndex) async {
    final attempt = current;
    if (attempt == null ||
        !attempt.isWordActivity ||
        wordIndex >= attempt.targetWords.length) return null;
    try {
      final res = await TherapyApiService.wordCheck(
          sessionId!, attempt.attemptId, audio, wordIndex);
      return switch (res['decision']) {
        'match' => ('✅ නියමයි! "${res['expected']}"', _C.green),
        'mismatch' => (
            '🙂 "${res['expected']}" කියලා ආයෙත් කියමුද?',
            Colors.orange.shade800
          ),
        _ => ('🔁 පැහැදිලි නැහැ, ආයෙත් කියන්න', Colors.orange.shade800),
      };
    } on ApiException catch (e) {
      // Without the language service the check is unavailable; the activity goes on.
      if (e.code == 'word_check_unavailable') return null;
      return (e.message, Colors.red);
    }
  }

  /// Reading / picture description: checks the whole recording; returns a short message for the recording sheet.
  static Future<(String, Color)?> checkSpeech(RecordedAudio audio) async {
    final attempt = current;
    if (attempt == null || !attempt.needsSpeechCheck) return null;
    try {
      final res = await TherapyApiService.speechCheck(
          sessionId!, attempt.attemptId, audio);
      final reading = res['mode'] == 'reading';
      final share = ((res['share'] as num?) ?? 0) * 100;
      return switch (res['decision']) {
        'match' => (
            reading
                ? '✅ නියමයි! ඡේදය හොඳින් කියෙව්වා (${share.round()}%)'
                : '✅ නියමයි! පින්තූරය හොඳින් විස්තර කළා',
            _C.green
          ),
        'partial' => (
            reading
                ? '🙂 ඡේදයෙන් ${share.round()}% ක් කියෙව්වා. ආයෙත් උත්සාහ කරමුද?'
                : '🙂 හොඳයි! තව දේවල් ගැනත් කියන්න පුළුවන්ද?',
            Colors.orange.shade800
          ),
        'mismatch' => (
            reading
                ? '🔁 ඡේදය නැවත කියවමු'
                : '🔁 පින්තූරයේ තියෙන දේවල් ගැන කියමු',
            Colors.orange.shade800
          ),
        _ => ('🔁 පැහැදිලි නැහැ, ආයෙත් කියන්න', Colors.orange.shade800),
      };
    } on ApiException catch (e) {
      if (e.code == 'word_check_unavailable')
        return null; // without the language service the activity goes on
      return (e.message, Colors.red);
    }
  }

  static Future<Map<String, dynamic>> complete() async {
    // An activity left open is abandoned on the server; its camera numbers are dropped.
    if (EngagementCamera.instance.running.value)
      await EngagementCamera.instance.stop();
    _cameraResult = null;
    final res = await TherapyApiService.complete(sessionId!);
    outcome = res['outcome'] is Map
        ? Map<String, dynamic>.from(res['outcome'] as Map)
        : null;
    current = null;
    awaitingResult = false;
    return res;
  }

  /// The child's sessions for the history and engagement screens (none in demo mode).
  static Future<List<dynamic>> history() async {
    final c = child;
    if (!isLive || c == null) return const [];
    try {
      return await TherapyApiService.getTherapyHistory(c.childId);
    } catch (error) {
      debugPrint('Could not load therapy history: $error');
      return const [];
    }
  }

  /// Routes to the existing screen for the server's activity.
  static String routeFor(_C3Attempt attempt) =>
      attempt.definition?.route ??
      '${_TherapyRoute.practiceActivity}/${attempt.appActivityId}';
}
