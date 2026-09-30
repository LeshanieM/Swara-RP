part of '../../therapy_ui.dart';

class _Engagement extends StatelessWidget {
  const _Engagement();

  static const _history = [0.55, 0.6, 0.58, 0.65, 0.7, 0.68, 0.72, 0.75, 0.7, 0.74, 0.72, 0.78];

  @override
  Widget build(BuildContext context) {
    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _BackHeader(title: ''),
          const Center(child: Text('අද ඔබේ ප්‍රගතිය 🌟', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _C.darkText))),
          const SizedBox(height: 4),
          const Center(child: Text('ඔබ අද කොච්චර හොඳින් පුහුණු වුණාද බලමු!', style: TextStyle(fontSize: 13, color: Colors.black54))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: const Column(children: [
              Text('8 / 10', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _C.blue)),
              Text('අද දින පුහුණුව', style: TextStyle(fontSize: 12, letterSpacing: 0.5, color: Colors.grey, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('නියමයි! ඔබ ඉතා උනන්දුවෙන් සහභාගී වුණා. 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _C.darkText)),
              SizedBox(height: 16),
              _CompRow(label: 'ක්‍රියාකාරකම් අවසන් කළා', value: 0.9),
              _CompRow(label: 'සෙමින් කතා කළා', value: 0.68),
              _CompRow(label: 'නැවත උත්සාහ කළා', value: 0.8),
              _CompRow(label: 'සතුටින් සහභාගී වුණා', value: 0.72),
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ඔබේ ප්‍රගතිය', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
              const SizedBox(height: 3),
              const Text('සැසියෙන් සැසියට ඔබ වැඩි දියුණු වෙමින් සිටී!', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 12),
              SizedBox(height: 70, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: _history.map((value) => Expanded(
                child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: value * 70, decoration: BoxDecoration(color: _C.green, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
              )).toList())),
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('පළමු සැසිය', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('අද', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final double value;
  const _CompRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))),
      Expanded(flex: 4, child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), color: _C.blue))),
      const SizedBox(width: 8),
      Text('${(value * 10).round()}/10', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

