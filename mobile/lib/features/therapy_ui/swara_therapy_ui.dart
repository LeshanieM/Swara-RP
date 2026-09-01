// ============================================================================
// SWARA THERAPY UI - Forest Adventure Speech Therapy Journey
// ============================================================================
// This journey is mounted by the app router at /c3/forest-therapy and is
// displayed inside the main app scaffold.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:async';


part 'therapy_state.dart';
part 'therapy_widgets.dart';
part 'screens/therapy_screens_1.dart';
part 'screens/therapy_screens_2.dart';
part 'screens/therapy_screens_3.dart';
part 'screens/therapy_history_screens.dart';

class _TherapyJourneyShell extends StatefulWidget {
  const _TherapyJourneyShell();
  @override
  State<_TherapyJourneyShell> createState() => _TherapyJourneyShellState();
}

class _TherapyJourneyShellState extends State<_TherapyJourneyShell> {
  int _idx = 0;
  _AppTheme _theme = _AppTheme.forest;

  static const List<Map<String, Object>> _screens = [
    {'title': '1. Home',                       'w': _S2Home()},             // 0
    {'title': '2. Theme Selection',            'w': _S3ThemeSelection()},   // 1
    {'title': '3. Welcome',                    'w': _S1Welcome()},          // 2
    {'title': '4. Character',                  'w': _S14Character()},       // 3
    {'title': '5. Adventure Plan',             'w': _S4AdventurePlan()},    // 4
    {'title': '6. Journey Map',                'w': _S5JourneyMap()},       // 5
    {'title': '7. Breathing Activity',         'w': _S21Breathing()},       // 6
    {'title': '8. New Challenge: Syllable',    'w': _S10AdaptiveNext(activityName: 'Syllable Practice', nextScreen: 8)}, // 7
    {'title': '9. Syllable Activity',          'w': _S20SyllablePractice()},// 8
    {'title': '10. New Challenge: Picture',    'w': _S10AdaptiveNext(activityName: 'Picture Description', nextScreen: 10)}, // 9
    {'title': '11. Picture Description Intro', 'w': _S6MilestoneIntro()},   // 10
    {'title': '12. Activity (Picture)',        'w': _S8Activity()},         // 11
    {'title': '13. New Challenge: Conversation','w': _S10AdaptiveNext(activityName: 'Guided Conversation', nextScreen: 13)}, // 12
    {'title': '14. Guided Conversation',       'w': _S11GuidedConv()},      // 13
    {'title': '15. Journey Complete Map',      'w': _S5bJourneyCompleteMap()},// 14
    {'title': '16. Session Complete',          'w': _S12SessionComplete()}, // 15
    {'title': '17. Overview',                  'w': _S13Progress()},        // 16
    {'title': '18. Therapy History',           'w': _S25TherapyHistory()},  // 17
    {'title': '19. Engagement & Trend',        'w': _S24Engagement()},      // 18
  ];

  void _go(int i) {
    if (i >= 0 && i < _screens.length) setState(() => _idx = i);
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      theme: _theme,
      onChanged: (t) => setState(() => _theme = t),
      child: _InheritedNav(
        index: _idx,
        go: _go,
        child: _screens[_idx]['w'] as Widget,
      ),
    );
  }
}
