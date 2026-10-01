import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/components/component4/screens/component4_intro.dart';
import 'package:swara/components/component4/screens/familiarity_screen.dart';
import 'package:swara/components/component4/screens/interest_selection.dart';
import 'package:swara/components/component4/screens/linguistic_analysis_screen.dart';
import 'package:swara/components/component4/screens/next_session_screen.dart';
import 'package:swara/components/component4/screens/personalization_process_screen.dart';
import 'package:swara/components/component4/screens/personalized_question_screen.dart';
import 'package:swara/components/component4/screens/personalized_topic_screen.dart';
import 'package:swara/components/component4/screens/results_screen.dart';
import 'package:swara/components/component4/screens/session_comparison_screen.dart';
import 'package:swara/components/component4/screens/speech_preparation_screen.dart';
import 'package:swara/components/component4/screens/speech_processing_screen.dart';
import 'package:swara/components/component4/screens/speech_recording_screen.dart';
import 'package:swara/components/component4/screens/transcription_screen.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/widgets/main_scaffold.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';
import 'package:swara/features/auth/presentation/screens/login_screen.dart';
import 'package:swara/features/auth/presentation/screens/register_screen.dart';
import 'package:swara/features/auth/presentation/screens/splash_screen.dart';
import 'package:swara/features/child/presentation/screens/child_home_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_processing_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_ready_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_result_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_upload_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_analysis_results_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_analysis_processing_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_analysis_upload_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_comparison_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_evaluation_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_overlay_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_technology_detail_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/video_timeline_screen.dart';
import 'package:swara/features/progress/presentation/screens/progress_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_completion_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_result_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_task_screen.dart';
import 'package:swara/features/therapist/presentation/screens/therapist_home_screen.dart';
import 'package:swara/features/therapy/therapy_ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRouterRefresh();
  ref.listen(authProvider, (previous, next) => authRefresh.refresh());

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isPublicRoute = location == '/splash' ||
          location == '/login' ||
          location == '/register';

      if (!authState.isInitialized) {
        return location == '/splash'
            ? null
            : Uri(
                path: '/splash',
                queryParameters: {'redirectTo': state.uri.toString()},
              ).toString();
      }

      if (!authState.isAuthenticated) {
        if (isPublicRoute) return null;
        return Uri(
          path: '/login',
          queryParameters: {'redirectTo': state.uri.toString()},
        ).toString();
      }

      if (isPublicRoute) {
        final redirectTo = state.uri.queryParameters['redirectTo'];
        if (redirectTo != null &&
            redirectTo.startsWith('/') &&
            !redirectTo.startsWith('//')) {
          return redirectTo;
        }
        return _homeLocation(authState.role);
      }

      if (location == '/' && authState.role == AppConstants.roleTherapist) {
        return '/therapist/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          redirectTo: state.uri.queryParameters['redirectTo'],
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(redirectTo: state.uri.queryParameters['redirectTo']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          redirectTo: state.uri.queryParameters['redirectTo'],
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(
          currentLocation: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ChildHomeScreen(),
          ),
          GoRoute(
            path: '/parent/home',
            builder: (context, state) => const ChildHomeScreen(),
          ),
          GoRoute(
            path: '/child/home',
            builder: (context, state) => const ChildHomeScreen(),
          ),
          GoRoute(
            path: '/therapist/home',
            builder: (context, state) => const TherapistHomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                const ProgressScreen(childId: 'child_1'),
          ),
          GoRoute(
            path: '/c1/record',
            builder: (context, state) => const SpeechTaskScreen(),
          ),
          GoRoute(
            path: '/c1/complete',
            builder: (context, state) => SpeechCompletionScreen(
              durationSeconds: state.extra as int? ?? 0,
            ),
          ),
          GoRoute(
            path: '/c1/result',
            builder: (context, state) => SpeechResultScreen(
              durationSeconds: state.extra as int? ?? 0,
            ),
          ),

          // Component 2 routes are intentionally preserved.
          GoRoute(
            path: '/c2/upload',
            builder: (context, state) =>
                const ConcomitantUploadScreen(childId: 'child_1'),
          ),
          GoRoute(
            path: '/c2/ready',
            builder: (context, state) => const ConcomitantReadyScreen(),
          ),
          GoRoute(
            path: '/c2/process',
            builder: (context, state) => ConcomitantProcessingScreen(
              assessmentData: state.extra as Map<String, dynamic>? ?? {},
            ),
          ),
          GoRoute(
            path: '/c2/result',
            builder: (context, state) => ConcomitantResultScreen(
              resultData: state.extra as Map<String, dynamic>? ?? {},
            ),
          ),
          GoRoute(
            path: '/c2/video/upload',
            builder: (context, state) =>
                const VideoAnalysisUploadScreen(childId: 'child_1'),
          ),
          GoRoute(
            path: '/c2/video/process/:id',
            builder: (context, state) => VideoAnalysisProcessingScreen(
              analysisId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/c2/video/results/:id',
            builder: (context, state) => VideoAnalysisResultsScreen(
              analysisId: state.pathParameters['id']!,
            ),
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
            builder: (context, state) => VideoComparisonScreen(
              analysisId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/c2/video/results/:id/timeline',
            builder: (context, state) => VideoTimelineScreen(
              analysisId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/c2/video/results/:id/overlay',
            builder: (context, state) => VideoOverlayScreen(
              analysisId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/c2/video/results/:id/metrics',
            builder: (context, state) => VideoEvaluationScreen(
              analysisId: state.pathParameters['id']!,
            ),
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
            redirect: (context, state) => '/c3/therapy/home',
          ),
          ..._therapyRoutes,

          // Component 4 routes are intentionally preserved.
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
            builder: (context, state) => FamiliarityScreen(
              selectedCategories: state.extra as List<InterestCategory>? ?? [],
            ),
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

  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });
  return router;
});

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final List<RouteBase> _therapyRoutes = [
  _therapyRoute('/c3/therapy/home', 'home'),
  _therapyRoute('/c3/therapy/theme-selection', 'theme-selection'),
  _therapyRoute('/c3/therapy/welcome', 'welcome'),
  _therapyRoute('/c3/therapy/character', 'character'),
  _therapyRoute('/c3/therapy/adventure-plan', 'adventure-plan'),
  _therapyRoute('/c3/therapy/journey-map', 'journey-map'),
  _therapyRoute('/c3/therapy/breathing', 'breathing'),
  _therapyRoute('/c3/therapy/adaptive-syllable', 'adaptive-syllable'),
  _therapyRoute('/c3/therapy/syllable-practice', 'syllable-practice'),
  _therapyRoute('/c3/therapy/adaptive-picture', 'adaptive-picture'),
  _therapyRoute('/c3/therapy/picture-intro', 'picture-intro'),
  _therapyRoute('/c3/therapy/picture-activity', 'picture-activity'),
  _therapyRoute('/c3/therapy/adaptive-conversation', 'adaptive-conversation'),
  _therapyRoute('/c3/therapy/guided-conversation', 'guided-conversation'),
  _therapyRoute('/c3/therapy/journey-complete', 'journey-complete'),
  _therapyRoute('/c3/therapy/session-complete', 'session-complete'),
  _therapyRoute('/c3/therapy/progress', 'progress'),
  _therapyRoute('/c3/therapy/history', 'history'),
  _therapyRoute('/c3/therapy/engagement', 'engagement'),
  _therapyRoute('/c3/therapy/activity-library', 'activity-library'),
  _therapyRoute('/c3/therapy/activity-detail', 'activity-detail'),
  _therapyRoute('/c3/therapy/feedback', 'feedback'),
  _therapyRoute('/c3/therapy/bandit-reasoning', 'bandit-reasoning'),
  _therapyRoute('/c3/therapy/therapist-dashboard', 'therapist-dashboard'),
  _therapyRoute(
      '/c3/therapy/therapist-knowledge-base', 'therapist-knowledge-base'),
];

GoRoute _therapyRoute(String path, String screen) => GoRoute(
      path: path,
      builder: (context, state) => SwaraTherapyUI(screen: screen),
    );

String _homeLocation(String role) {
  switch (role) {
    case AppConstants.roleParent:
      return '/parent/home';
    case AppConstants.roleTherapist:
      return '/therapist/home';
    case AppConstants.roleChild:
      return '/child/home';
    default:
      return '/';
  }
}

class _AuthRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
