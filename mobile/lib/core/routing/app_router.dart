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
import 'package:swara/features/concomitant/presentation/screens/video_analysis_upload_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_analysis_processing_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_analysis_results_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_technology_detail_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_comparison_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_timeline_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_overlay_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_evaluation_screen.dart';
import 'package:swara/features/progress/presentation/screens/progress_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/features/auth/presentation/screens/login_screen.dart';
import 'package:swara/features/auth/presentation/screens/register_screen.dart';

import 'package:swara/components/component4/screens/component4_intro.dart';
import 'package:swara/components/component4/screens/interest_selection.dart';
import 'package:swara/components/component4/screens/familiarity_screen.dart';
import 'package:swara/components/component4/screens/personalization_process_screen.dart';
import 'package:swara/components/component4/screens/personalized_topic_screen.dart';
import 'package:swara/components/component4/screens/personalized_question_screen.dart';
import 'package:swara/components/component4/screens/speech_preparation_screen.dart';
import 'package:swara/components/component4/screens/speech_recording_screen.dart';
import 'package:swara/components/component4/screens/speech_processing_screen.dart';
import 'package:swara/components/component4/screens/transcription_screen.dart';
import 'package:swara/components/component4/screens/linguistic_analysis_screen.dart';
import 'package:swara/components/component4/screens/results_screen.dart';
import 'package:swara/components/component4/screens/session_comparison_screen.dart';
import 'package:swara/components/component4/screens/next_session_screen.dart';

import 'package:swara/features/therapy/therapy_ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return _appRouter;
});

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final _appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(redirectTo: state.uri.queryParameters['redirectTo']),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(redirectTo: state.uri.queryParameters['redirectTo']),
    ),
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
        // Component 2 - research mode: multi-technology CV comparison on ONE video
        GoRoute(
          path: '/c2/video/upload',
          builder: (context, state) => const VideoAnalysisUploadScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c2/video/process/:id',
          builder: (context, state) => VideoAnalysisProcessingScreen(analysisId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c2/video/results/:id',
          builder: (context, state) => VideoAnalysisResultsScreen(analysisId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c2/video/results/:id/tech/:tech',
          builder: (context, state) => VideoTechnologyDetailScreen(
            analysisId: state.pathParameters['id']!,
            techKey: state.pathParameters['tech']!,
          ),
        ),
        GoRoute(
          path: '/c2/video/results/:id/compare',
          builder: (context, state) => VideoComparisonScreen(analysisId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c2/video/results/:id/timeline',
          builder: (context, state) => VideoTimelineScreen(analysisId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c2/video/results/:id/overlay',
          builder: (context, state) => VideoOverlayScreen(analysisId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c2/video/results/:id/metrics',
          builder: (context, state) => VideoEvaluationScreen(analysisId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/c2/result/:id',
          builder: (context, state) => ConcomitantResultScreen(
            resultData: {'id': state.pathParameters['id'] ?? 'mock_c2'},
          ),
        ),

        // Component 3 - Guided Therapy
        GoRoute(
          path: '/c3/forest-therapy',
          builder: (context, state) => const SwaraTherapyUI(),
        ),

        // Component 4 - Spontaneous Analysis
        GoRoute(
          path: '/c4',
          builder: (context, state) => const Component4Intro(),
        ),
        GoRoute(
          path: '/c4/interest',
          builder: (context, state) => const InterestSelectionScreen(),
        ),
        GoRoute(
          path: '/c4/familiarity',
          builder: (context, state) {
            final categories = state.extra as List<InterestCategory>? ?? [];
            return FamiliarityScreen(selectedCategories: categories);
          },
        ),
        GoRoute(
          path: '/c4/personalization_processing',
          builder: (context, state) => const PersonalizationProcessScreen(),
        ),
        GoRoute(
          path: '/c4/topic',
          builder: (context, state) => const PersonalizedTopicScreen(),
        ),
        GoRoute(
          path: '/c4/question',
          builder: (context, state) => const PersonalizedQuestionScreen(),
        ),
        GoRoute(
          path: '/c4/preparation',
          builder: (context, state) => const SpeechPreparationScreen(),
        ),
        GoRoute(
          path: '/c4/record',
          builder: (context, state) => const SpeechRecordingScreen(),
        ),
        GoRoute(
          path: '/c4/speech_processing',
          builder: (context, state) => const SpeechProcessingScreen(),
        ),
        GoRoute(
          path: '/c4/transcription',
          builder: (context, state) => const TranscriptionScreen(),
        ),
        GoRoute(
          path: '/c4/analysis',
          builder: (context, state) => const LinguisticAnalysisScreen(),
        ),
        GoRoute(
          path: '/c4/results',
          builder: (context, state) => const ResultsScreen(),
        ),
        GoRoute(
          path: '/c4/comparison',
          builder: (context, state) => const SessionComparisonScreen(),
        ),
        GoRoute(
          path: '/c4/next_session',
          builder: (context, state) => const NextSessionScreen(),
        ),
      ],
    ),
  ],
);
