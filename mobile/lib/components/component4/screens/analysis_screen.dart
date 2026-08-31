import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/communication_score_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Recording received',
    'Speech detected',
    'Sinhala speech recognized',
    'Sentences identified',
    'Language patterns analyzed',
    'Communication features analyzed',
    'Result prepared'
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    final service = CommunicationScoreService();
    
    // Animate steps concurrently with the analysis task
    service.analyzeRecording('dummy_path'); // just trigger to simulate delay
    
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
    
    if (mounted) {
      context.pushReplacement('/c4/child_result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Looking at Your Story 🔎',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'ඔයාගේ කතාව බලමු 🔎',
                style: TextStyle(fontSize: 20, color: Colors.blueAccent),
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
                    bool isDone = idx <= _currentStep;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isDone ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDone ? Colors.black87 : Colors.grey,
                                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.blueAccent),
            ],
          ),
        ),
      ),
    );
  }
}
