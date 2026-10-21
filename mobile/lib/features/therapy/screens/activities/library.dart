part of '../../therapy_ui.dart';

class _Library extends StatelessWidget {
  const _Library();

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackHeader(title: ''),
            const Center(
              child: Text(
                'ප්‍රතිකාර ක්‍රියාකාරකම් එකතුව',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _C.darkText,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Clinical Activity Library (5 Core Activities)',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: theme.accentColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All 5 activities are clinically designed and fully performable with voice practice & scoring.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.darkText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._therapyActivities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LItem(
                  icon: activity.emoji,
                  title: activity.title,
                  sub: activity.focus,
                  onTap: () => nav?.go(activity.route),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _LItem extends StatelessWidget {
  final String icon, title, sub;
  final VoidCallback onTap;

  const _LItem({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: _C.blue.withValues(alpha: 0.1),
              radius: 22,
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _C.darkText,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                sub,
                style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _C.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Play', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _C.blue)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _C.blue),
                ],
              ),
            ),
            onTap: onTap,
          ),
        ),
      );
}
