part of '../../therapy_ui.dart';

class _ActivityState extends State<_Activity> {
  bool _recordingCompleted = false;

  @override
  Widget build(BuildContext context) {
    final attempt = _C3Session.attemptFor('picture-description');
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('ඔබට පෙනෙන්නේ මොනවාද?',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        if (attempt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(attempt.prompts.first,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ),
        const SizedBox(height: 14),
        // The item's picture; the theme's scene when there is none.
        _ItemPicture(asset: attempt?.image, height: 220),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _TherapyMicButton(
            nextScreen: _TherapyRoute.adaptiveConversation,
            onRecordingStopped: () {
              if (attempt != null) _C3Session.recorded(0);
              setState(() => _recordingCompleted = true);
            },
            onAudio: attempt?.needsSpeechCheck == true
                ? _C3Session.checkSpeech
                : null,
            onComplete: attempt == null
                ? null
                : () => _C3Session.finishAndContinue(context),
          ),
          GestureDetector(
              onTap: () {},
              child: Column(children: [
                CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.amber.shade100,
                    child: const Icon(Icons.lightbulb_outline,
                        color: Colors.amber, size: 24)),
                const SizedBox(height: 6),
                const Text('Need help?',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
        ]),
        if (_recordingCompleted) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14)),
            child: const Text('ඔබේ පිළිතුර පටිගත කිරීම සම්පූර්ණයි!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: _C.green)),
          ),
          const SizedBox(height: 12),
          _Btn(
              text: 'මඟ පෙන්වන කතාබහට යන්න',
              onTap: () => _C3Session.finishAndContinue(context,
                  demoRoute: _TherapyRoute.adaptiveConversation)),
        ],
        if (attempt != null) const _SkipActivityButton(),
        const SizedBox(height: 24),
      ]),
    ));
  }
}
