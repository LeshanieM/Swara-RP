import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/widgets/main_scaffold.dart';
import 'package:swara/features/child/presentation/screens/child_home_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_task_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_completion_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_result_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_upload_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_ready_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_processing_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_result_screen.dart';
import 'package:swara/features/communication/presentation/screens/communication_task_screen.dart';
import 'package:swara/features/communication/presentation/screens/communication_result_screen.dart';
import 'package:swara/features/progress/presentation/screens/progress_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swara/components/component3/theme_selection_screen.dart';
import 'package:swara/components/component3/personalized_plan_screen.dart';
import 'package:swara/components/component3/activity_screen.dart';
import 'package:swara/components/component3/final_score_screen.dart';
import 'package:swara/components/component3/slp_summary_screen.dart';
import 'package:swara/components/component3/models/activity_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return _appRouter;
});

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final _appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(
          currentLocation: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ChildHomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProgressScreen(childId: 'child_1'),
        ),
        
        GoRoute(
          path: '/c1/record',
          builder: (context, state) => const SpeechTaskScreen(),
        ),
        GoRoute(
          path: '/c1/complete',
          builder: (context, state) {
            final duration = state.extra as int? ?? 0;
            return SpeechCompletionScreen(durationSeconds: duration);
          }
        ),
        GoRoute(
          path: '/c1/result',
          builder: (context, state) {
            final duration = state.extra as int? ?? 0;
            return SpeechResultScreen(durationSeconds: duration);
          }
        ),
        
        // Component 2 - Secondary Behaviour
        GoRoute(
          path: '/c2/upload',
          builder: (context, state) => const ConcomitantUploadScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c2/ready',
          builder: (context, state) => const ConcomitantReadyScreen(),
        ),
        GoRoute(
          path: '/c2/process',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return ConcomitantProcessingScreen(assessmentData: data);
          },
        ),
        GoRoute(
          path: '/c2/result',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return ConcomitantResultScreen(resultData: data);
          },
        ),
        GoRoute(
          path: '/c2/result/:id',
          builder: (context, state) => ConcomitantResultScreen(
            resultData: {'id': state.pathParameters['id'] ?? 'mock_c2'},
          ),
        ),

        // Component 3 - Guided Therapy
        GoRoute(
          path: '/c3/theme',
          builder: (context, state) => const ThemeSelectionScreen(),
        ),
        GoRoute(
          path: '/c3/plan',
          builder: (context, state) {
            final themeId = state.extra as String? ?? 'jungle';
            return PersonalizedPlanScreen(themeId: themeId);
          },
        ),
        GoRoute(
          path: '/c3/activity/:index',
          builder: (context, state) {
            final index = int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final activities = extra['activities'] as List<ActivityModel>? ?? [];
            final themeId = extra['themeId'] as String? ?? 'jungle';
            final results = extra['results'] as Map<String, int>? ?? {};
            
            return ActivityScreen(
              activityIndex: index,
              activities: activities,
              themeId: themeId,
              results: results,
            );
          },
        ),
        GoRoute(
          path: '/c3/final',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final activities = extra['activities'] as List<ActivityModel>? ?? [];
            final themeId = extra['themeId'] as String? ?? 'jungle';
            final results = extra['results'] as Map<String, int>? ?? {};
            
            return FinalScoreScreen(
              results: results,
              activities: activities,
              themeId: themeId,
            );
          },
        ),
        GoRoute(
          path: '/c3/summary',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final activities = extra['activities'] as List<ActivityModel>? ?? [];
            final themeId = extra['themeId'] as String? ?? 'jungle';
            final results = extra['results'] as Map<String, int>? ?? {};
            
            return SlpSummaryScreen(
              results: results,
              activities: activities,
              themeId: themeId,
            );
          },
        ),

        // Component 4 - Spontaneous Analysis
        GoRoute(
          path: '/c4/task',
          builder: (context, state) => const CommunicationTaskScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c4/result',
          builder: (context, state) => const CommunicationResultScreen(),
        ),
      ],
    ),
  ],
);