import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Component4HomeScreen extends StatelessWidget {
  const Component4HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Spontaneous Communication'),
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
              const Icon(
                Icons.mic_none,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              const Text(
                'Personalized Communication Challenge',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'පුද්ගලික කථන අභියෝගය',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Let\'s see how you can tell your own story!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'ඔයාගේම කතාව කොච්චර හොඳින් කියන්න පුළුවන්ද බලමු!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/c4/personalization');
                  },
                  icon: const Icon(Icons.star, size: 28),
                  label: const Text(
                    '🎯 Start My Challenge\n🎯 මගේ අභියෝගය ආරම්භ කරමු',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      'This is not a test you can fail.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'මේක ඔයාට අසමත් වෙන්න තියෙන පරීක්ෂණයක් නෙවෙයි.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Just tell your story in your own words.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    Text(
                      'ඔයාගේම වචනවලින් ඔයාගේ කතාව කියන්න.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
