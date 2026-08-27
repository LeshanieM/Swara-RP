import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/widgets/main_scaffold.dart';
import 'package:swara/features/child/presentation/screens/child_home_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_record_screen.dart';
import 'package:swara/features/speech/presentation/screens/speech_result_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_dashboard_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/new_concomitant_assessment_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_recording_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_processing_screen.dart';
import 'package:swara/features/concomitant/presentation/screens/concomitant_result_screen.dart';
import 'package:swara/features/storybook/presentation/screens/storybook_screen.dart';
import 'package:swara/features/therapy_ui/swara_therapy_ui.dart';
import 'package:swara/features/communication/presentation/screens/communication_task_screen.dart';
import 'package:swara/features/communication/presentation/screens/communication_result_screen.dart';
import 'package:swara/features/progress/presentation/screens/progress_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          path: '/activities',
          builder: (context, state) => const StorybookScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProgressScreen(childId: 'child_1'),
        ),
        
        // Component 1 - Speech Check
        GoRoute(
          path: '/c1/record',
          builder: (context, state) => const SpeechRecordScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c1/result',
          builder: (context, state) => const SpeechResultScreen(assessmentId: 'mock_c1'),
        ),
        
        // Component 2 - Secondary Behaviour
        GoRoute(
          path: '/c2/dashboard',
          builder: (context, state) => const ConcomitantDashboardScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c2/new',
          builder: (context, state) => const NewConcomitantAssessmentScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c2/record',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return ConcomitantRecordingScreen(assessmentData: data);
          },
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
          builder: (context, state) => const ConcomitantResultScreen(resultData: {'id': 'mock_c2'}),
        ),
        GoRoute(
          path: '/c2/result/:id',
          builder: (context, state) => ConcomitantResultScreen(
            resultData: {'id': state.pathParameters['id'] ?? 'mock_c2'},
          ),
        ),

        // Component 3 - Guided Therapy
        GoRoute(
          path: '/c3/activities',
          builder: (context, state) => const StorybookScreen(childId: 'child_1'),
        ),
        GoRoute(
          path: '/c3/forest-therapy',
          builder: (context, state) => const SwaraTherapyUI(),
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