// ============================================================================
// SWARA THERAPY UI - Forest Adventure Speech Therapy Journey
// ============================================================================
// This journey is mounted by the app router at /c3/forest-therapy and is
// displayed inside the main app scaffold.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'therapy_api_service.dart';
part 'therapy_state.dart';
part 'therapy_widgets.dart';
part 'screens/setup/welcome.dart';
part 'screens/setup/home.dart';
part 'screens/setup/theme_selection.dart';
part 'screens/setup/state.dart';
part 'screens/setup/adventure_plan.dart';
part 'screens/session/journey_map.dart';
part 'screens/activities/milestone_intro.dart';
part 'screens/activities/activity.dart';
part 'screens/activities/activity_state.dart';
part 'screens/activities/feedback.dart';
part 'screens/activities/adaptive_next.dart';
part 'screens/activities/adaptive_next_state.dart';
part 'screens/activities/guided_conv.dart';
part 'screens/session/session_complete.dart';
part 'screens/session/progress.dart';
part 'screens/setup/character.dart';
part 'screens/dashboard/therapist_dash.dart';
part 'screens/activities/library.dart';
part 'screens/activities/detail.dart';
part 'screens/activities/syllable_practice.dart';
part 'screens/activities/breathing.dart';

part 'screens/dashboard/bandit_reasoning.dart';
part 'screens/dashboard/therapist_k_b.dart';
part 'screens/session/journey_complete_map.dart';
part 'screens/dashboard/engagement.dart';
part 'screens/dashboard/therapy_history.dart';

class _TherapyJourneyShell extends StatefulWidget {
  const _TherapyJourneyShell();
  @override
  State<_TherapyJourneyShell> createState() => _TherapyJourneyShellState();
}

class _TherapyJourneyShellState extends State<_TherapyJourneyShell> {
  int _idx = 0;
  _AppTheme _theme = _AppTheme.forest;

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final saved = await StorageService.getString(AppConstants.c3PreferredThemeKey);
    final theme = _AppThemeX.fromStorageId(saved);
    if (!mounted || theme == _theme) return;
    setState(() => _theme = theme);
  }

  static const List<Map<String, Object>> _screens = [
    {'title': '1. Home',                       'w': _Home()},             // 0
    {'title': '2. Theme Selection',            'w': _ThemeSelection()},   // 1
    {'title': '3. Welcome',                    'w': _Welcome()},          // 2
    {'title': '4. Character',                  'w': _Character()},       // 3
    {'title': '5. Adventure Plan',             'w': _AdventurePlan()},    // 4
    {'title': '6. Journey Map',                'w': _JourneyMap()},       // 5
    {'title': '7. Breathing Activity',         'w': _Breathing()},       // 6
    {'title': '8. New Challenge: Syllable',    'w': _AdaptiveNext(activityName: 'Syllable Practice', nextScreen: 8)}, // 7
    {'title': '9. Syllable Activity',          'w': _SyllablePractice()},// 8
    {'title': '10. New Challenge: Picture',    'w': _AdaptiveNext(activityName: 'Picture Description', nextScreen: 10)}, // 9
    {'title': '11. Picture Description Intro', 'w': _MilestoneIntro()},   // 10
    {'title': '12. Activity (Picture)',        'w': _Activity()},         // 11
    {'title': '13. New Challenge: Conversation','w': _AdaptiveNext(activityName: 'Guided Conversation', nextScreen: 13)}, // 12
    {'title': '14. Guided Conversation',       'w': _GuidedConv()},      // 13
    {'title': '15. Journey Complete Map',      'w': _JourneyCompleteMap()},// 14
    {'title': '16. Session Complete',          'w': _SessionComplete()}, // 15
    {'title': '17. Overview',                  'w': _Progress()},        // 16
    {'title': '18. Therapy History',           'w': _TherapyHistory()},  // 17
    {'title': '19. Engagement & Trend',        'w': _Engagement()},      // 18
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
