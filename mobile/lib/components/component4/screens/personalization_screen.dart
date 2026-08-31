import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/topic_recommendation_service.dart';
import '../mock/component4_mock_data.dart';
import '../models/communication_topic.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({Key? key}) : super(key: key);

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Component 1 ✓',
    'Component 2 ✓',
    'Age ✓',
    'Therapist Assessment ✓',
    'Creating Topic...'
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
    
    final topic = await TopicRecommendationService().generateTopic(Component4MockData.mockAssessment);
    
    if (mounted) {
      context.pushReplacement('/c4/topic', extra: topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.blueAccent),
                const SizedBox(height: 32),
                const Text(
                  'Creating Your Challenge...',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'ඔයාගේ අභියෝගය සූදානම් කරනවා...',
                  style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _steps.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String text = entry.value;
                      bool isActive = idx <= _currentStep;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: 16,
                                color: isActive ? Colors.black87 : Colors.grey,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Finding the right challenge for you...',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const Text(
                  'ඔයාට ගැළපෙන අභියෝගය සොයනවා...',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                if (_currentStep == _steps.length - 1) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Almost ready! 🌟',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
