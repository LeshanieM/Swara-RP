import 'package:flutter/material.dart';
import '../widgets/metric_card.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechMetricsScreen extends StatelessWidget {
  const SpeechMetricsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('කථන මිනුම්')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MetricCard(title: 'කථන කාලය', value: '01:12', icon: Icons.timer),
          SizedBox(height: 8),
          MetricCard(title: 'කථන වේගය', value: '2.8', subtitle: 'අක්ෂර/තත්පරයට', icon: Icons.speed),
          SizedBox(height: 8),
          MetricCard(title: 'විරාම ගණන', value: 'විරාම 7ක්', icon: Icons.pause_circle_outline),
          SizedBox(height: 8),
          MetricCard(title: 'සාමාන්‍ය විරාම කාලය', value: 'තත්පර 1.1ක්', icon: Icons.hourglass_bottom),
          SizedBox(height: 8),
          MetricCard(title: 'පිළිතුර ඇරඹීමට ගත වූ කාලය', value: 'තත්පර 2.4ක්', icon: Icons.pending_actions),
          SizedBox(height: 24),
          Text('හඳුනාගත් කථන පැකිළීම්', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
          SizedBox(height: 8),
          MetricCard(title: 'සිදුවීම්', value: '8', icon: Icons.warning_amber_rounded),
        ],
      ),
    );
  }
}
