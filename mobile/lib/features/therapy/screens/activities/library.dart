part of '../../therapy_ui.dart';

class _Library extends StatelessWidget {
  const _Library();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(
            child: Text('Activity Library',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText))),
        const SizedBox(height: 16),
        Text(
          '${_therapyActivities.length} activities',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ..._therapyActivities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LItem(
              icon: activity.emoji,
              title: activity.title,
              sub: activity.focus,
              onTap: () => nav?.go(activity.route),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _LItem extends StatelessWidget {
  final String icon, title, sub;
  final VoidCallback onTap;
  const _LItem(
      {required this.icon,
      required this.title,
      required this.sub,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            leading: Text(icon, style: const TextStyle(fontSize: 22)),
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _C.darkText)),
            subtitle: Text(sub,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _C.blue),
            onTap: onTap,
          ),
        ),
      );
}

// 17. DETAIL
