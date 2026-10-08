part of '../../therapy_ui.dart';

class _ThemeSelectionState extends State<_ThemeSelection> {
  String _cat = 'All';
  final _cats = ['All', 'Nature', 'Ocean', 'Fantasy'];
  _AppTheme? _picked;
  bool _saving = false;

  _AppTheme _current(BuildContext context) =>
      _picked ?? _InheritedTheme.of(context)?.theme ?? _AppTheme.forest;

  Future<void> _save(BuildContext context) async {
    if (_saving) return;
    final theme = _current(context);
    final ts = _InheritedTheme.of(context);
    setState(() => _saving = true);
    ts?.onChanged(theme);
    await StorageService.saveString(AppConstants.c3PreferredThemeKey, theme.storageId);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${theme.emoji} ${theme.name} saved as your world'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current(context);
    final list = _AppTheme.values
        .where((t) => _cat == 'All' || t.category == _cat)
        .toList();
    final saved = _InheritedTheme.of(context)?.theme ?? _AppTheme.forest;
    final hasUnsavedChange = cur != saved;

    return _BgScaffold(
        paintScene: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _BackHeader(title: ''),
            const _Plaque(text: 'ඔබේ ලෝකය තෝරන්න 🗺️', fontSize: 18),
            const SizedBox(height: 4),
            const Text('ඔබ කැමති කතා පුහුණු ලෝකය තෝරා Save කරන්න. මෙය පෙනුම පමණි — ක්‍රියාකාරකම් එලෙසම පවතී.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                  children: _cats.map((c) {
                final sel = _cat == c;
                return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c == 'All' ? 'All (6 Worlds)' : c,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : _C.darkText)),
                      selected: sel,
                      selectedColor: _C.blue,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: sel ? _C.blue : Colors.grey.shade300)),
                      onSelected: (v) {
                        if (v) setState(() => _cat = c);
                      },
                    ));
              }).toList()),
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _ThemeCard(
                  theme: list[i],
                  isSelected: cur == list[i],
                  onTap: () => setState(() => _picked = list[i])),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cur.accentColor, width: 2)),
              child: Column(children: [
                Row(children: [
                  _InheritedTheme(
                    theme: cur,
                    onChanged: (_) {},
                    child: const _Mascot(size: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${cur.emoji} ${cur.name}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cur.accentColor)),
                        Text('Guide: ${cur.mascotName} • ${cur.speechPerk}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      ])),
                ]),
                const SizedBox(height: 12),
                _Btn(
                    text: _saving
                        ? 'Saving...'
                        : hasUnsavedChange
                            ? 'Save ${cur.name}'
                            : '${cur.name} Saved',
                    onTap: _saving ? () {} : () => _save(context)),
              ]),
            ),
            const SizedBox(height: 20),
          ]),
        ));
  }
}

class _ThemeCard extends StatelessWidget {
  final _AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeCard(
      {required this.theme, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: isSelected ? theme.accentColor : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1.2),
            boxShadow: [
              BoxShadow(
                  color: isSelected
                      ? theme.accentColor.withValues(alpha: 0.18)
                      : Colors.black12,
                  blurRadius: isSelected ? 12 : 5,
                  offset: const Offset(0, 3))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              _ScenePreview(theme: theme, height: 125),
              Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${theme.emoji} ${theme.name}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  )),
              if (isSelected)
                Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: theme.accentColor, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    )),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(theme.journeyName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? theme.accentColor : _C.darkText))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color:
                        isSelected ? theme.accentColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(isSelected ? 'ACTIVE' : 'SELECT',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(theme.tagline,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _Chip(icon: '🐾', text: 'Guide: ${theme.mascotName}'),
              _Chip(icon: '✨', text: theme.speechPerk),
            ]),
          ]),
        ));
  }
}

class _Chip extends StatelessWidget {
  final String icon, text;
  const _Chip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$icon $text',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
      );
}

// 4. ADVENTURE PLAN
