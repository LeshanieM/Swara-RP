import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Preparation'),
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
              const Text(
                'Ready to Tell Your Story? 🎙️',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'ඔයාගේ කතාව කියන්න සූදානම්ද? 🎙️',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Remember:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    SizedBox(height: 24),
                    Text('Take your time.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('ඔයාට ඕනෑ තරම් කාලය ගන්න.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    SizedBox(height: 16),
                    Text('Use your own words.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('ඔයාගේම වචන භාවිතා කරන්න.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    SizedBox(height: 16),
                    Text('There is no perfect answer.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('හරිම එකම උත්තරයක් නැහැ.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pushReplacement('/c4/record');
                  },
                  icon: const Icon(Icons.mic, size: 32),
                  label: const Text(
                    '🎙️ Start Speaking\n🎙️ කතා කරන්න පටන් ගමු',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
