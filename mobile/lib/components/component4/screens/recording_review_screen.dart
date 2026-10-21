import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/audio_player.dart';
import 'package:swara/core/theme/app_theme.dart';

class RecordingReviewScreen extends StatelessWidget {
  const RecordingReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.groundRead,
      appBar: AppBar(
        title: const Text('පටිගත කළ දේ පරීක්ෂා කරන්න'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'යවන්න සූදානම්ද? 🚀',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 24),
              const Text(
                'ඔයාගේ කතාව කියපු ආකාරය අපි බලමු.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.text),
              ),
              const SizedBox(height: 48),
              const Text(
                'ඔයාගේ කතාවට සවන් දෙන්න',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const AudioPlayerWidget(),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pushReplacement('/c4/record');
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('↻ නැවත පටිගත කරන්න', textAlign: TextAlign.center),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pushReplacement('/c4/analysis');
                      },
                      icon: const Icon(Icons.check),
                      label: const Text(
                        '✓ මෙය භාවිතා කරන්න',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
