import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'models/assessment_model.dart';
import 'models/activity_model.dart';
import 'recommendation/activity_recommendation_engine.dart';

class PersonalizedPlanScreen extends StatefulWidget {
  final String themeId;
  const PersonalizedPlanScreen({super.key, required this.themeId});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  late List<ActivityModel> _activities;

  @override
  void initState() {
    super.initState();
    // Use mock data
    final assessment = AssessmentData.mock();
    _activities = ActivityRecommendationEngine.generateActivityPlan(assessment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ඔබේ කථන චාරිකාව 🌟', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDeep),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your Speech Adventure 🌟',
                style: TextStyle(fontSize: 20, color: AppColors.textLight, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ඔබ වෙනුවෙන් ක්‍රියාකාරකම් 4ක් සූදානම් කර ඇත.',
                style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '4 activities prepared for you',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Journey illustration
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryWash,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Text('🏁', style: TextStyle(fontSize: 32)),
                    Text('→', style: TextStyle(fontSize: 20, color: AppColors.primary)),
                    Text('🌟', style: TextStyle(fontSize: 32)),
                    Text('→', style: TextStyle(fontSize: 20, color: AppColors.primary)),
                    Text('🌟', style: TextStyle(fontSize: 32)),
                    Text('→', style: TextStyle(fontSize: 20, color: AppColors.primary)),
                    Text('🌟', style: TextStyle(fontSize: 32)),
                    Text('→', style: TextStyle(fontSize: 20, color: AppColors.primary)),
                    Text('🌟', style: TextStyle(fontSize: 32)),
                    Text('→', style: TextStyle(fontSize: 20, color: AppColors.primary)),
                    Text('🏆', style: TextStyle(fontSize: 32)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    final isFirst = index == 0;
                    return _ActivityPreviewCard(
                      activity: activity,
                      index: index,
                      isLocked: !isFirst,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.push('/c3/activity/0', extra: {
                    'activities': _activities,
                    'themeId': widget.themeId,
                    'results': <String, int>{},
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Column(
                  children: [
                    Text('චාරිකාව ආරම්භ කරන්න', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Start Adventure', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPreviewCard extends StatelessWidget {
  final ActivityModel activity;
  final int index;
  final bool isLocked;

  const _ActivityPreviewCard({
    required this.activity,
    required this.index,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider, width: 1),
      ),
      color: isLocked ? AppColors.surfaceRaised : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade200 : AppColors.primaryWash,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey : AppColors.primaryDeep,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.nameSi,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey : AppColors.text,
                    ),
                  ),
                  Text(
                    activity.nameEn,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLocked ? Colors.grey : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Icon(Icons.lock_rounded, color: Colors.grey)
            else
              const Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryDeep, size: 32),
          ],
        ),
      ),
    );
  }
}
