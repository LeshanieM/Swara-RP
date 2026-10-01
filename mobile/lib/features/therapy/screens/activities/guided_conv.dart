part of '../../therapy_ui.dart';

class _GuidedConv extends StatelessWidget {
  const _GuidedConv();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('කතා කරමු!',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        Text(
            'Your ${theme.adventureWord} friend ${theme.mascotName} has a question for you.',
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ]),
                  child: Text(
                      'What do you like most about the ${theme.name.toLowerCase()}?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _C.darkText)))),
          const SizedBox(width: 8),
          const _Mascot(size: 90),
        ]),
        const SizedBox(height: 30),
        const _TherapyMicButton(
            nextScreen: _TherapyRoute.journeyComplete, radius: 36),
        const SizedBox(height: 16),
        TextButton(
            onPressed: () => nav?.go(_TherapyRoute.sessionComplete),
            child: const Text('Skip Activity',
                style: TextStyle(color: Colors.grey, fontSize: 14))),
        const SizedBox(height: 8),
        _Btn(
            text: 'අවසන් කරන්න',
            onTap: () => nav?.go(_TherapyRoute.sessionComplete)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 11. SESSION COMPLETE
