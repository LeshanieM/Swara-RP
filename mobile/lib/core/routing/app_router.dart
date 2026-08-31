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
import 'package:swara/features/progress/presentation/screens/progress_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swara/components/component4/screens/component4_home_screen.dart';
import 'package:swara/components/component4/screens/personalization_screen.dart';
import 'package:swara/components/component4/screens/topic_screen.dart';
import 'package:swara/components/component4/screens/preparation_screen.dart';
import 'package:swara/components/component4/screens/recording_screen.dart';
import 'package:swara/components/component4/screens/recording_review_screen.dart';
import 'package:swara/components/component4/screens/analysis_screen.dart';
import 'package:swara/components/component4/screens/child_result_screen.dart';
import 'package:swara/components/component4/screens/communication_report_screen.dart';
import 'package:swara/components/component4/screens/speech_metrics_screen.dart';
import 'package:swara/components/component4/screens/language_metrics_screen.dart';
import 'package:swara/components/component4/screens/communication_metrics_screen.dart';
import 'package:swara/components/component4/models/communication_topic.dart';

import 'package:swara/components/component3/theme_selection_screen.dart';
import 'package:swara/components/component3/personalized_plan_screen.dart';
import 'package:swara/components/component3/activity_screen.dart';
import 'package:swara/components/component3/final_score_screen.dart';
import 'package:swara/components/component3/slp_summary_screen.dart';
import 'package:swara/components/component3/models/activity_model.dart';
import 'package:swara/features/therapy_ui/swara_therapy_ui.dart';

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
        GoRoute(
          path: '/c3/forest-therapy',
          builder: (context, state) => const SwaraTherapyUI(),
        ),

        // Component 4 - Spontaneous Analysis
        GoRoute(
          path: '/c4',
          builder: (context, state) => const Component4HomeScreen(),
        ),
        GoRoute(
          path: '/c4/personalization',
          builder: (context, state) => const PersonalizationScreen(),
        ),
        GoRoute(
          path: '/c4/topic',
          builder: (context, state) {
            final topic = state.extra as CommunicationTopic;
            return TopicScreen(topic: topic);
          },
        ),
        GoRoute(
          path: '/c4/preparation',
          builder: (context, state) => const PreparationScreen(),
        ),
        GoRoute(
          path: '/c4/record',
          builder: (context, state) => const RecordingScreen(),
        ),
        GoRoute(
          path: '/c4/review',
          builder: (context, state) => const RecordingReviewScreen(),
        ),
        GoRoute(
          path: '/c4/analysis',
          builder: (context, state) => const AnalysisScreen(),
        ),
        GoRoute(
          path: '/c4/child_result',
          builder: (context, state) => const ChildResultScreen(),
        ),
        GoRoute(
          path: '/c4/report',
          builder: (context, state) => const CommunicationReportScreen(),
        ),
        GoRoute(
          path: '/c4/metrics/speech',
          builder: (context, state) => const SpeechMetricsScreen(),
        ),
        GoRoute(
          path: '/c4/metrics/language',
          builder: (context, state) => const LanguageMetricsScreen(),
        ),
        GoRoute(
          path: '/c4/metrics/communication',
          builder: (context, state) => const CommunicationMetricsScreen(),
        ),
      ],
    ),
  ],
);