import 'package:flutter/material.dart';
import '../widgets/metric_card.dart';

class SpeechMetricsScreen extends StatelessWidget {
  const SpeechMetricsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Metrics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MetricCard(title: 'Speech Duration', value: '01:12', icon: Icons.timer),
          SizedBox(height: 8),
          MetricCard(title: 'Speech Rate', value: '2.8', subtitle: 'syllables/sec', icon: Icons.speed),
          SizedBox(height: 8),
          MetricCard(title: 'Pause Frequency', value: '7 pauses', icon: Icons.pause_circle_outline),
          SizedBox(height: 8),
          MetricCard(title: 'Mean Pause Duration', value: '1.1 sec', icon: Icons.hourglass_bottom),
          SizedBox(height: 8),
          MetricCard(title: 'Response Latency', value: '2.4 sec', icon: Icons.pending_actions),
          SizedBox(height: 24),
          Text('Observed Fluency Events', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 8),
          MetricCard(title: 'Events', value: '8', icon: Icons.warning_amber_rounded),
        ],
      ),
    );
  }
}
