import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/metric_card.dart';

class CommunicationReportScreen extends StatelessWidget {
  const CommunicationReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Communication Assessment\nකථන සන්නිවේදන ඇගයීම', style: TextStyle(fontSize: 14)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Session Information'),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Age', value: '10 years'),
                        _InfoRow(label: 'Date', value: 'Aug 31, 2026'),
                        _InfoRow(label: 'Topic', value: 'A Day at the Zoo'),
                        _InfoRow(label: 'Difficulty', value: 'Level 2 - Story'),
                        _InfoRow(label: 'Recording Duration', value: '01:12'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Assessment Context'),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _InfoRow(label: 'C1 Severity', value: 'Moderate'),
                        _InfoRow(label: 'C1 Type', value: 'Repetition'),
                        _InfoRow(label: 'C2 Behavior Score', value: '61'),
                        _InfoRow(label: 'SLP Score', value: '70'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Detailed Metrics'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/c4/metrics/speech'),
                        child: const MetricCard(
                          title: 'Speech',
                          value: 'Profile',
                          icon: Icons.record_voice_over,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/c4/metrics/language'),
                        child: const MetricCard(
                          title: 'Language',
                          value: 'Profile',
                          icon: Icons.language,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.push('/c4/metrics/communication'),
                  child: const MetricCard(
                    title: 'Communication',
                    value: 'Profile',
                    icon: Icons.forum,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Your Communication Journey\nඔයාගේ කථන ගමන'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Communication Task Performance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Mock Chart
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('[Chart: 72 -> 76 -> 84]', style: TextStyle(color: Colors.blue))),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your communication-task performance has changed over your previous sessions.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
