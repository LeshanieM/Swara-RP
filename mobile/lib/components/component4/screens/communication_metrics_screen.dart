import 'package:flutter/material.dart';
import '../widgets/metric_card.dart';
import 'package:swara/core/theme/app_theme.dart';

class CommunicationMetricsScreen extends StatelessWidget {
  const CommunicationMetricsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communication Profile\nසන්නිවේදන පැතිකඩ', style: TextStyle(fontSize: 16))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MetricCard(title: 'මාතෘකාවට අදාළ බව', value: '88%', icon: Icons.track_changes),
          SizedBox(height: 8),
          MetricCard(title: 'තොරතුරු අන්තර්ගතය', value: '82%', icon: Icons.extension),
          SizedBox(height: 8),
          MetricCard(title: 'කතාවේ පිළිවෙළ', value: '78%', icon: Icons.menu_book),
          SizedBox(height: 8),
          MetricCard(title: 'පිළිතුරේ සම්පූර්ණ බව', value: '90%', icon: Icons.done_all),
          SizedBox(height: 8),
          MetricCard(title: 'සහභාගීත්වය', value: '86%', icon: Icons.record_voice_over),
        ],
      ),
    );
  }
}
