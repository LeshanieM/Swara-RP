part of '../../therapy_ui.dart';

class _Welcome extends StatelessWidget {
  const _Welcome();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(children: [
        const SizedBox(height: 10),
        const _Plaque(text: 'ආයුබෝවන් Aseliya!'),
        const SizedBox(height: 24),
        const _Mascot(size: 180),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(theme.welcomeQuote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _C.darkText,
                    height: 1.3)),
            const SizedBox(height: 16),
            _Btn(
                text: 'ඉදිරියට යමු!',
                onTap: () => nav?.go(_TherapyRoute.character)),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 2. HOME
