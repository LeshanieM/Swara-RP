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
  final String screen;
  const _TherapyJourneyShell({required this.screen});
  @override
  State<_TherapyJourneyShell> createState() => _TherapyJourneyShellState();
}

class _TherapyJourneyShellState extends State<_TherapyJourneyShell> {
  _AppTheme _theme = _AppTheme.forest;

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final saved =
        await StorageService.getString(AppConstants.c3PreferredThemeKey);
    final theme = _AppThemeX.fromStorageId(saved);
    if (!mounted || theme == _theme) return;
    setState(() => _theme = theme);
  }

  Widget _screenForRoute() {
    switch (widget.screen) {
      case _TherapyRoute.home:
        return const _Home();
      case _TherapyRoute.themeSelection:
        return const _ThemeSelection();
      case _TherapyRoute.welcome:
        return const _Welcome();
      case _TherapyRoute.character:
        return const _Character();
      case _TherapyRoute.adventurePlan:
        return const _AdventurePlan();
      case _TherapyRoute.journeyMap:
        return const _JourneyMap();
      case _TherapyRoute.breathing:
        return const _Breathing();
      case _TherapyRoute.adaptiveSyllable:
        return const _AdaptiveNext(
          activityName: 'Syllable Practice',
          nextScreen: _TherapyRoute.syllablePractice,
        );
      case _TherapyRoute.syllablePractice:
        return const _SyllablePractice();
      case _TherapyRoute.adaptivePicture:
        return const _AdaptiveNext(
          activityName: 'Picture Description',
          nextScreen: _TherapyRoute.pictureIntro,
        );
      case _TherapyRoute.pictureIntro:
        return const _MilestoneIntro();
      case _TherapyRoute.pictureActivity:
        return const _Activity();
      case _TherapyRoute.adaptiveConversation:
        return const _AdaptiveNext(
          activityName: 'Guided Conversation',
          nextScreen: _TherapyRoute.guidedConversation,
        );
      case _TherapyRoute.guidedConversation:
        return const _GuidedConv();
      case _TherapyRoute.journeyComplete:
        return const _JourneyCompleteMap();
      case _TherapyRoute.sessionComplete:
        return const _SessionComplete();
      case _TherapyRoute.progress:
        return const _Progress();
      case _TherapyRoute.history:
        return const _TherapyHistory();
      case _TherapyRoute.engagement:
        return const _Engagement();
      case _TherapyRoute.activityLibrary:
        return const _Library();
      case _TherapyRoute.activityDetail:
        return const _Detail();
      case _TherapyRoute.feedback:
        return const _Feedback();
      case _TherapyRoute.banditReasoning:
        return const _BanditReasoning();
      case _TherapyRoute.therapistDashboard:
        return const _TherapistDash();
      case _TherapyRoute.therapistKnowledgeBase:
        return const _TherapistKB();
      default:
        return const _Home();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      theme: _theme,
      onChanged: (t) => setState(() => _theme = t),
      child: _InheritedNav(
        go: (route) => context.push('/c3/therapy/$route'),
        child: _screenForRoute(),
      ),
    );
  }
}

class _TherapyRoute {
  static const home = 'home';
  static const themeSelection = 'theme-selection';
  static const welcome = 'welcome';
  static const character = 'character';
  static const adventurePlan = 'adventure-plan';
  static const journeyMap = 'journey-map';
  static const breathing = 'breathing';
  static const adaptiveSyllable = 'adaptive-syllable';
  static const syllablePractice = 'syllable-practice';
  static const adaptivePicture = 'adaptive-picture';
  static const pictureIntro = 'picture-intro';
  static const pictureActivity = 'picture-activity';
  static const adaptiveConversation = 'adaptive-conversation';
  static const guidedConversation = 'guided-conversation';
  static const journeyComplete = 'journey-complete';
  static const sessionComplete = 'session-complete';
  static const progress = 'progress';
  static const history = 'history';
  static const engagement = 'engagement';
  static const activityLibrary = 'activity-library';
  static const activityDetail = 'activity-detail';
  static const feedback = 'feedback';
  static const banditReasoning = 'bandit-reasoning';
  static const therapistDashboard = 'therapist-dashboard';
  static const therapistKnowledgeBase = 'therapist-knowledge-base';
}
