import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/services/c4_flow.dart';

class SessionComparisonScreen extends StatefulWidget {
  const SessionComparisonScreen({super.key});

  @override
  State<SessionComparisonScreen> createState() => _SessionComparisonScreenState();
}

class _SessionComparisonScreenState extends State<SessionComparisonScreen> {
  late final Future<C4Comparison> _comparison = C4Flow.comparison();

  static String _change(num? before, num? now, String up, String down, String same) {
    if (before == null || now == null) return 'The first session to compare with';
    if (now > before) return up;
    if (now < before) return down;
    return same;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<C4Comparison>(
      future: _comparison,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final c = snapshot.data ?? const C4Comparison();
        return _build(context, c, error: snapshot.error);
      },
    );
  }

  Widget _build(BuildContext context, C4Comparison c, {Object? error}) {
    String num1(double? x) => x == null ? '—' : x.toStringAsFixed(1);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 13, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'කාලයත් සමඟ සන්නිවේදනය',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Communication Over Time',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    _buildComparisonCard(
                      title: 'MLU',
                      val1: num1(c.mluBefore),
                      val2: num1(c.mluNow),
                      description: _change(c.mluBefore, c.mluNow, 'Increased from Session 1', 'Lower than Session 1', 'Same as Session 1'),
                      icon: Icons.show_chart,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonCard(
                      title: 'NDW',
                      val1: c.ndwBefore?.toString() ?? '—',
                      val2: c.ndwNow?.toString() ?? '—',
                      description: _change(c.ndwBefore, c.ndwNow, 'More different words were used', 'Fewer different words this time', 'The same number of different words'),
                      icon: Icons.bar_chart,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonCard(
                      title: 'Stuttering (%SS)',
                      val1: num1(c.percentSSBefore),
                      val2: num1(c.percentSSNow),
                      description: _change(c.percentSSBefore, c.percentSSNow, 'More stuttering than last time', 'Less stuttering than last time', 'About the same'),
                      icon: Icons.graphic_eq,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonCard(
                      title: 'Response Duration',
                      val1: fmtClock(c.durationBefore),
                      val2: fmtClock(c.durationNow),
                      description: _change(c.durationBefore, c.durationNow, 'Longer spontaneous response', 'A shorter response this time', 'About the same length'),
                      icon: Icons.timer,
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/next_session'),
                      child: const Text('View Next Step'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String val1,
    required String val2,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.lgAll,
        boxShadow: AppElevation.card,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text('Session 1', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(val1, style: AppTextStyles.heading2.copyWith(color: AppColors.textLight)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight, size: 32),
              ),
              Column(
                children: [
                  Text('Session 2', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(val2, style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: AppRadii.pillAll,
            ),
            child: Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
