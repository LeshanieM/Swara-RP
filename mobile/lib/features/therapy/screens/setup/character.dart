part of '../../therapy_ui.dart';

class _Character extends StatelessWidget {
  const _Character();
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
        const Text('ඔබේ කතා පුහුණු යාළුවා',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 4),
        Text(theme.characterScreenTitle,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54)),
        const SizedBox(height: 20),
        const _Mascot(size: 190),
        const SizedBox(height: 20),
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ]),
            child: Column(children: [
              Text(
                  'මම ${theme.mascotName}. අපි එකට සෙමින්, පැහැදිලිව කතා කිරීම පුහුණු කරමු!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _C.darkText,
                      height: 1.4)),
              const SizedBox(height: 10),
              Text(theme.mascotDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54, height: 1.4)),
            ])),
        const SizedBox(height: 24),
        _Btn(
            text: 'මගේ සැලැස්ම බලන්න',
            onTap: () => nav?.go(_TherapyRoute.adventurePlan)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 15. THERAPIST DASHBOARD
