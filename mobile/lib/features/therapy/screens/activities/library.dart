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
        const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(children: [
              _CTab(title: 'All', sel: true),
              _CTab(title: 'Speaking', sel: false),
              _CTab(title: 'Breathing', sel: false),
              _CTab(title: 'Reading', sel: false),
            ])),
        const SizedBox(height: 16),
        _LItem(
            icon: '🖼️',
            title: 'Picture Description',
            sub: 'Focus: Fluency & Expression',
            onTap: () => nav?.go(_TherapyRoute.pictureIntro)),
        const SizedBox(height: 10),
        _LItem(
            icon: '🎙️',
            title: 'Guided Conversation',
            sub: 'Focus: Pausing & Phrasing',
            onTap: () => nav?.go(_TherapyRoute.guidedConversation)),
        const SizedBox(height: 10),
        _LItem(
            icon: '🔤',
            title: 'Syllable Practice',
            sub: 'Focus: Easy Onset',
            onTap: () => nav?.go(_TherapyRoute.syllablePractice)),
        const SizedBox(height: 10),
        _LItem(
            icon: '🫁',
            title: 'Breathing Exercise',
            sub: 'Focus: Relaxation',
            onTap: () => nav?.go(_TherapyRoute.breathing)),
        const SizedBox(height: 20),
        _Btn(text: '+ Add Activity', onTap: () {}),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _CTab extends StatelessWidget {
  final String title;
  final bool sel;
  const _CTab({required this.title, required this.sel});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? _C.blue : Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: Text(title,
            style: TextStyle(
                color: sel ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      );
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
