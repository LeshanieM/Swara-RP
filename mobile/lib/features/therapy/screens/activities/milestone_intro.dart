part of '../../therapy_ui.dart';

class _MilestoneIntro extends StatelessWidget {
  const _MilestoneIntro();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('පින්තූරය විස්තර කරමු',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        const _Mascot(size: 170, pose: 'magnifier'),
        const SizedBox(height: 20),
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ]),
            child: Text(
                "Let's look at a picture in ${theme.name} and describe what you see!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _C.darkText))),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.timer_outlined, color: Colors.black54, size: 18),
          SizedBox(width: 6),
          Text('මිනිත්තු 5',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54)),
        ]),
        const SizedBox(height: 24),
        _Btn(
            text: 'ක්‍රියාකාරකම අරඹන්න',
            onTap: () => nav?.go(_TherapyRoute.pictureActivity)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 7. ACTIVITY (PICTURE)
