part of '../../therapy_ui.dart';

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _C.darkText),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Speech Therapy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's Plan",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              const Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text("Today's Therapy Plan",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                      SizedBox(height: 6),
                      Text('අද දින පුහුණුව ආරම්භ කිරීමට සූදානම්ද?',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                SizedBox(width: 8),
                _Mascot(size: 74),
              ]),
              const SizedBox(height: 16),
              _Btn(
                  text: 'අද දින ප්‍රතිකාර සැලැස්ම අරඹන්න',
                  onTap: () async {
                    try {
                      if (_C3Session.isLive) {
                        await _C3Session.start();
                      } else {
                        await _DemoPlan.clearPendingForCurrentUser();
                      }
                    } catch (error, stackTrace) {
                      debugPrint('Could not start the therapy session: '
                          '$error\n$stackTrace');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error is ApiException
                              ? error.message
                              : 'Could not start a therapy session: $error'),
                        ),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    nav?.go(_TherapyRoute.welcome);
                  }),
            ]),
          ),
          const _ContinueSession(),
          if (_C3Session.isLive && EngagementCamera.isSupported) ...[
            const SizedBox(height: 12),
            const _CameraEngagementToggle(),
          ],
          const SizedBox(height: 20),
          _item(context, '🎨', 'ත්‍රාසජනක ලෝක තෝරන්න',
              () => nav?.go(_TherapyRoute.themeSelection)),
          const SizedBox(height: 10),
          _item(context, '🏆', 'මගේ ජයග්‍රහණ',
              () => nav?.go(_TherapyRoute.progress)),
          const SizedBox(height: 10),
          _item(context, '📋', 'ප්‍රතිකාර ඉතිහාසය',
              () => nav?.go(_TherapyRoute.history)),
          const SizedBox(height: 10),
          _item(context, '🗣️', 'Therapy Activity Library',
              () => nav?.go(_TherapyRoute.activityLibrary)),
          const SizedBox(height: 10),
          const _HomeStats(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              Text('💡', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Daily Tip',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _C.darkText)),
                    SizedBox(height: 4),
                    Text(
                        'Remember to take deep breaths and speak slowly during your exercises.',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _item(BuildContext ctx, String em, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          leading: Text(em, style: const TextStyle(fontSize: 22)),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _C.darkText)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: _C.blue),
          onTap: onTap,
        ),
      ),
    );
  }
}

// 3. THEME SELECTION

/// Parent setting: measure engagement with the front camera during activities. Off by default; changing it
/// needs parent mode. Only face numbers leave the phone, never images.
class _CameraEngagementToggle extends ConsumerStatefulWidget {
  const _CameraEngagementToggle();

  @override
  ConsumerState<_CameraEngagementToggle> createState() =>
      _CameraEngagementToggleState();
}

class _CameraEngagementToggleState
    extends ConsumerState<_CameraEngagementToggle> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _C3Session.cameraAllowed().then((on) {
      if (mounted) setState(() => _on = on);
    });
  }

  Future<void> _change(bool on) async {
    if (!await ensureParentMode(context, ref)) return;
    await StorageService.setBool(AppConstants.c3CameraEngagementKey, on);
    if (mounted) setState(() => _on = on);
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18)),
        child: SwitchListTile(
          value: _on,
          onChanged: _change,
          secondary: const Icon(Icons.videocam_rounded, color: _C.darkText),
          title: const Text(
              kIsWeb
                  ? 'Use the camera during activities'
                  : 'Measure engagement with the camera',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _C.darkText)),
          subtitle: const Text(
              kIsWeb
                  ? 'Webcam preview only; engagement uses activity signals. Video stays in your browser.'
                  : 'Parent setting. Only face numbers are sent, never video.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      );
}

/// Live: the child's day streak (consecutive days with a completed session) and stars (one per completed activity),
/// from the server's C3 summary. Demo mode has no history, so it shows dashes.
class _HomeStats extends StatefulWidget {
  const _HomeStats();
  @override
  State<_HomeStats> createState() => _HomeStatsState();
}

class _HomeStatsState extends State<_HomeStats> {
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = _C3Session.child;
    if (!_C3Session.isLive || c == null) return;
    try {
      final s = await TherapyApiService.summary(c.childId);
      if (mounted) setState(() => _summary = s);
    } catch (e) {
      debugPrint('C3 summary failed: $e');
    }
  }

  Widget _tile(String emoji, String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    final streak = s?['streakDays'] as num?;
    final stars = s?['stars'] as num?;
    return Row(children: [
      _tile(
          '🔥',
          'Current Streak',
          streak == null ? '—' : '$streak ${streak == 1 ? 'Day' : 'Days'}',
          Colors.orange.shade50),
      const SizedBox(width: 12),
      _tile('⭐', 'Total Stars', stars == null ? '—' : '$stars',
          Colors.green.shade50),
    ]);
  }
}

/// Live: when today's session was left part-way (the app was closed, or the child paused), offer to continue it.
/// The server keeps a session open for a few hours; after that it is closed as "not finished".
class _ContinueSession extends StatefulWidget {
  const _ContinueSession();
  @override
  State<_ContinueSession> createState() => _ContinueSessionState();
}

class _ContinueSessionState extends State<_ContinueSession> {
  Map<String, dynamic>? _active;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await _C3Session.resumable();
      if (mounted) setState(() => _active = a);
    } catch (e) {
      debugPrint('Could not look for an open session: $e');
    }
  }

  Future<void> _continue() async {
    final active = _active;
    if (active == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _C3Session.resume(active);
      if (!mounted) return;
      _InheritedNav.of(context)?.go(_TherapyRoute.adaptiveSyllable);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiException.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    if (active == null) return const SizedBox.shrink();
    final done = (active['activitiesDone'] as num?)?.toInt() ?? 0;
    final max = (active['session']?['maxActivities'] as num?)?.toInt() ?? 5;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.woodMid, width: 2),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
              "Today's session is not finished: $done of $max activities done.",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _C.darkText)),
          const Text('අද සැසිය තවම අවසන් නැහැ. දිගටම කරමුද?',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          _Btn(
              text: _busy ? '...' : 'Continue today\'s session',
              onTap: _continue),
        ]),
      ),
    );
  }
}
