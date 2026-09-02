import 'package:flutter/material.dart';
import '../widgets/metric_card.dart';
import 'package:swara/core/theme/app_theme.dart';

class LanguageMetricsScreen extends StatelessWidget {
  const LanguageMetricsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Profile\nභාෂා පැතිකඩ', style: TextStyle(fontSize: 16))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MetricCard(title: 'Mean Length of Utterance (MLU)', value: '4.2', subtitle: 'Average length of spoken utterances.', icon: Icons.format_size),
          SizedBox(height: 8),
          MetricCard(title: 'Utterances', value: '18', icon: Icons.chat_bubble_outline),
          SizedBox(height: 8),
          MetricCard(title: 'Lexical Diversity', value: '0.61', icon: Icons.auto_awesome),
          SizedBox(height: 8),
          MetricCard(title: 'Average Utterance Length', value: '4.2 units', icon: Icons.straighten),
          SizedBox(height: 8),
          MetricCard(title: 'Information Content', value: '82%', icon: Icons.info_outline),
        ],
      ),
    );
  }
}
