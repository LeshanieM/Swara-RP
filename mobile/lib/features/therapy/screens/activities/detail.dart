part of '../../therapy_ui.dart';

class _Detail extends StatelessWidget {
  const _Detail();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Picture Description',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ]),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Technique',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Pausing & Phrasing',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _C.darkText)),
                  SizedBox(height: 16),
                  Text('Suitable For',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('• Moderate Severity\n• Repetition Type\n• Age 6 - 10',
                      style: TextStyle(
                          fontSize: 14, color: _C.darkText, height: 1.4)),
                  SizedBox(height: 16),
                  Text('Description',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                      'Child describes a picture in short phrases with encouragement of smooth easy pauses.',
                      style: TextStyle(
                          fontSize: 14, color: _C.darkText, height: 1.4)),
                ])),
        const SizedBox(height: 24),
        _Btn(
            text: 'Edit Activity',
            onTap: () => nav?.go(_TherapyRoute.activityLibrary)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// ----------------------------------------------------------------------------
// 20. SYLLABLE PRACTICE — one of the five bandit arms
// ----------------------------------------------------------------------------
