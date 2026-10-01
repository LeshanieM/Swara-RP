part of '../../therapy_ui.dart';

class _Home extends StatelessWidget {
  const _Home();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _C.darkText),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Speech Therapy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's Plan",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(children: [
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text("Today's Therapy Plan",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                      SizedBox(height: 6),
                      Text('අද දින පුහුණුව ආරම්භ කිරීමට සූදානම්ද?',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                const SizedBox(width: 8),
                const _Mascot(size: 74),
              ]),
              const SizedBox(height: 16),
              _Btn(
                  text: 'අද දින ප්‍රතිකාර සැලැස්ම අරඹන්න',
                  onTap: () => nav?.go(_TherapyRoute.welcome)),
            ]),
          ),
          const SizedBox(height: 20),
          _item(context, '🎨', 'ත්‍රාසජනක ලෝක තෝරන්න',
              () => nav?.go(_TherapyRoute.themeSelection)),
          const SizedBox(height: 10),
          _item(context, '🏆', 'මගේ ජයග්‍රහණ',
              () => nav?.go(_TherapyRoute.progress)),
          const SizedBox(height: 10),
          _item(context, '📋', 'ප්‍රතිකාර ඉතිහාසය',
              () => nav?.go(_TherapyRoute.history)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('🔥', style: TextStyle(fontSize: 24)),
                      SizedBox(height: 8),
                      Text('Current Streak',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('5 Days',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('⭐', style: TextStyle(fontSize: 24)),
                      SizedBox(height: 8),
                      Text('Total Stars',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('1,250',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Daily Tip',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _C.darkText)),
                    SizedBox(height: 4),
                    Text(
                        'Remember to take deep breaths and speak slowly during your exercises.',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _item(BuildContext ctx, String em, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          leading: Text(em, style: const TextStyle(fontSize: 22)),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _C.darkText)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: _C.blue),
          onTap: onTap,
        ),
      ),
    );
  }
}

// 3. THEME SELECTION
