part of '../../therapy_ui.dart';

class _AdaptiveNext extends StatefulWidget {
  final String activityName;
  final String nextScreen;
  const _AdaptiveNext(
      {this.activityName = 'Guided Conversation',
      this.nextScreen = _TherapyRoute.guidedConversation});

  @override
  State<_AdaptiveNext> createState() => _AdaptiveNextState();
}
