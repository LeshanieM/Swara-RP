part of '../../therapy_ui.dart';

class _AdaptiveNextState extends State<_AdaptiveNext> {
  String? _fetchedActivityName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNextActivity();
  }

  Future<void> _fetchNextActivity() async {
    final name = await TherapyApiService.getNextActivity('MOCK_CHILD_001', 'SESSION_001');
    if (mounted) {
      setState(() {
        _fetchedActivityName = name;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final displayActivity = _fetchedActivityName ?? widget.activityName;
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('නව අභියෝගය', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const Text('විවෘත විය!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.blue)),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.topCenter, children: [
          Container(
            margin: const EdgeInsets.only(top: 40), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(24), border: Border.all(color: _C.woodMid, width: 3), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Column(children: [
              const SizedBox(height: 60),
              const Text('ඔබේ ඊළඟ ක්‍රියාකාරකම', style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 6),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(displayActivity, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.darkText)),
            ]),
          ),
          const _Mascot(size: 130),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'අරඹමු!', onTap: _isLoading ? () {} : () => nav?.go(widget.nextScreen)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 10. GUIDED CONVERSATION
