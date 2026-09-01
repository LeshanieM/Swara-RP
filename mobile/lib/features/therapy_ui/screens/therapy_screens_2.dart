part of '../swara_therapy_ui.dart';

class _S6MilestoneIntro extends StatelessWidget {
  const _S6MilestoneIntro();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('පින්තූරය විස්තර කරමු', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        const _Mascot(size: 170, pose: 'magnifier'),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Text("Let's look at a picture in ${theme.name} and describe what you see!", textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.darkText))),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.timer_outlined, color: Colors.black54, size: 18), SizedBox(width: 6),
          Text('මිනිත්තු 5', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'ක්‍රියාකාරකම අරඹන්න', onTap: () => nav?.go(11)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 7. ACTIVITY (PICTURE)
class _S8Activity extends StatefulWidget {
  const _S8Activity();

  @override
  State<_S8Activity> createState() => _S8ActivityState();
}

class _S8ActivityState extends State<_S8Activity> {
  bool _recordingCompleted = false;

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('ඔබට පෙනෙන්නේ මොනවාද?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 14),
        const _SceneWidget(height: 220),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _TherapyMicButton(
            nextScreen: 12,
            onRecordingStopped: () => setState(() => _recordingCompleted = true),
          ),
          GestureDetector(onTap: () {}, child: Column(children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.amber.shade100, child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24)),
            const SizedBox(height: 6),
            const Text('Need help?', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
        ]),
        if (_recordingCompleted) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14)),
            child: const Text('ඔබේ පිළිතුර පටිගත කිරීම සම්පූර්ණයි!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _C.green)),
          ),
          const SizedBox(height: 12),
          _Btn(text: 'මඟ පෙන්වන කතාබහට යන්න', onTap: () => nav?.go(12)),
        ],
        const SizedBox(height: 24),
      ]),
    ));
  }
}

// 8. FEEDBACK
class _S9Feedback extends StatelessWidget {
  const _S9Feedback();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Great Job!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        const _Mascot(size: 160),
        const SizedBox(height: 16),
        const Text('You did a wonderful job\ndescribing the scene with confidence!', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _C.darkText, height: 1.4)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_half_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_outline_rounded, color: _C.gold, size: 32),
        ]),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: _C.chipBg, borderRadius: BorderRadius.circular(12)),
          child: const Text('8 / 10 Fluency Score', style: TextStyle(fontWeight: FontWeight.bold, color: _C.blue))),
        const SizedBox(height: 24),
        _Btn(text: 'Continue', onTap: () => nav?.go(12)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 9. ADAPTIVE NEXT
class _S10AdaptiveNext extends StatelessWidget {
  final String activityName;
  final int nextScreen;
  const _S10AdaptiveNext({this.activityName = 'Guided Conversation', this.nextScreen = 13});
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('නව අභියෝගය', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const Text('විවෘත විය!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.blue)),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.topCenter, children: [
          Container(
            margin: const EdgeInsets.only(top: 40), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(24), border: Border.all(color: _C.woodMid, width: 3), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Column(children: [
              const SizedBox(height: 60),
              const Text('ඔබේ ඊළඟ ක්‍රියාකාරකම', style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 6),
              Text(activityName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.darkText)),
            ]),
          ),
          const _Mascot(size: 130),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'අරඹමු!', onTap: () => nav?.go(nextScreen)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 10. GUIDED CONVERSATION
class _S11GuidedConv extends StatelessWidget {
  const _S11GuidedConv();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('කතා කරමු!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        Text('Your ${theme.adventureWord} friend ${theme.mascotName} has a question for you.', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
            child: Text('What do you like most about the ${theme.name.toLowerCase()}?', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.darkText)))),
          const SizedBox(width: 8),
          const _Mascot(size: 90),
        ]),
        const SizedBox(height: 30),
        const _TherapyMicButton(nextScreen: 14, radius: 36),
        const SizedBox(height: 16),
        TextButton(onPressed: () => nav?.go(15), child: const Text('Skip Activity', style: TextStyle(color: Colors.grey, fontSize: 14))),
        const SizedBox(height: 8),
        _Btn(text: 'අවසන් කරන්න', onTap: () => nav?.go(15)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 11. SESSION COMPLETE
class _S12SessionComplete extends StatelessWidget {
  const _S12SessionComplete();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const _Plaque(text: 'ගමන සම්පූර්ණයි!', fontSize: 18),
        const SizedBox(height: 16),
        const _Mascot(size: 160, pose: 'trophy'),
        const SizedBox(height: 12),
        const Text('අද ඔබ ඉතා හොඳින් කළා!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _StCard(label: 'Activities', value: '4 / 4', emoji: '🧩'),
          _StCard(label: 'Score', value: '8 / 10', emoji: '⭐️'),
          _StCard(label: 'Time', value: '25 min', emoji: '⏱️'),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'සාරාංශය බලන්න', onTap: () => nav?.go(16)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _StCard extends StatelessWidget {
  final String label, value, emoji;
  const _StCard({required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) => Container(
    width: 95, padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );
}

// 13. PROGRESS
class _S13Progress extends StatelessWidget {
  const _S13Progress();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(child: Text('ඔබේ සාරාංශය', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText))),
        const SizedBox(height: 3),
        const Center(child: Text('ඔබ සම්පූර්ණ කළ ක්‍රියාකාරකම්', style: TextStyle(fontSize: 13, color: Colors.black54))),
        Center(child: Text(theme.journeyName, style: const TextStyle(fontSize: 13, color: Colors.black54))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('සම්පූර්ණ කළ ක්‍රියාකාරකම්', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('4 / 4', style: TextStyle(fontWeight: FontWeight.bold, color: _C.blue)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 1.0, backgroundColor: Colors.blue.shade50, color: theme.accentColor, minHeight: 10, borderRadius: BorderRadius.circular(5)),
          ])),
        const SizedBox(height: 20),
        const Text('ඔබේ ජයග්‍රහණ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ABadge(emoji: '🥇', label: 'පළමු පියවර'),
          _ABadge(emoji: '🗣️', label: 'දක්ෂ කථිකයා'),
          _ABadge(emoji: '🌟', label: 'ගවේෂකයා'),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'ගමන් සිතියම බලන්න', onTap: () => nav?.go(5)),
        const SizedBox(height: 12),
        _Btn(text: 'මුල් පිටුවට යන්න', onTap: () => nav?.go(0)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _ABadge extends StatelessWidget {
  final String emoji, label;
  const _ABadge({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    CircleAvatar(radius: 28, backgroundColor: _C.chipBg, child: Text(emoji, style: const TextStyle(fontSize: 26))),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _C.darkText)),
  ]);
}

// 14. CHARACTER
class _S14Character extends StatelessWidget {
  const _S14Character();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('ඔබේ කතා පුහුණු යාළුවා', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 4),
        Text(theme.characterScreenTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 20),
        const _Mascot(size: 190),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Column(children: [
            Text('මම ${theme.mascotName}. අපි එකට සෙමින්, පැහැදිලිව කතා කිරීම පුහුණු කරමු!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText, height: 1.4)),
            const SizedBox(height: 10),
            Text(theme.mascotDescription, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
          ])),
        const SizedBox(height: 24),
        _Btn(text: 'මගේ සැලැස්ම බලන්න', onTap: () => nav?.go(4)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 15. THERAPIST DASHBOARD
class _S15TherapistDash extends StatelessWidget {
  const _S15TherapistDash();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(child: Text("Aseliya's Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText))),
        Center(child: Text(theme.journeyName, style: const TextStyle(fontSize: 13, color: Colors.black54))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const _MCard(title: 'Severity', value: 'Moderate'),
          const _MCard(title: 'Stutter Type', value: 'Repetition'),
          // Replaced "Psych Score" (out-of-scope) with Engagement metric
          GestureDetector(
            onTap: () => nav?.go(18),
            child: const _MCard(title: 'Engagement', value: '0.78'),
          ),
        ]),
        const SizedBox(height: 20),
        const Text('Recent Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 10),
        const _ARow(icon: '🖼️', title: 'Picture Description', score: '8 / 10'),
        const SizedBox(height: 8),
        const _ARow(icon: '📖', title: 'Story Retelling', score: '7 / 10'),
        const SizedBox(height: 8),
        const _ARow(icon: '🎙️', title: 'Guided Conversation', score: '8 / 10'),
        const SizedBox(height: 24),
        _Btn(text: 'Engagement', onTap: () => nav?.go(18)),
        const SizedBox(height: 10),
        _Btn(text: 'View Full Report', onTap: () => nav?.go(17)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _MCard extends StatelessWidget {
  final String title, value;
  const _MCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    width: 100, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: Column(children: [
      Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _C.darkText)),
    ]),
  );
}

class _ARow extends StatelessWidget {
  final String icon, title, score;
  const _ARow({required this.icon, required this.title, required this.score});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText))),
      Text(score, style: const TextStyle(fontWeight: FontWeight.bold, color: _C.blue)),
    ]),
  );
}

// 16. LIBRARY
