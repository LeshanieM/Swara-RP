import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChildResultScreen extends StatelessWidget {
  const ChildResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Result'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  '🌟 Great Job!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '🌟 නියමයි!',
                  style: TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You completed your speaking challenge!\nඔයාගේ කථන අභියෝගය සම්පූර්ණ කළා!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '84 / 100',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      Text(
                        'Communication Performance',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'කථන ක්රියාකාරීත්වය',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      SizedBox(height: 16),
                      Divider(color: Colors.white54),
                      SizedBox(height: 8),
                      Text('🎯 Challenge Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('⏱️ 01:12 speaking time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildFeedbackCard('💬 You shared your ideas', 'ඔයාගේ අදහස් හොඳින් කිව්වා'),
                const SizedBox(height: 12),
                _buildFeedbackCard('🎯 You stayed with the topic', 'ඔයා මාතෘකාවට අදාළව කතා කළා'),
                const SizedBox(height: 12),
                _buildFeedbackCard('🌟 You completed the challenge', 'ඔයා අභියෝගය සම්පූර්ණ කළා'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/c4/report');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('See Detailed Results\nමගේ ප්රතිඵල බලන්න', textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done\nඅවසන් කරන්න', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String eng, String sin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eng, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 4),
          Text(sin, style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
        ],
      ),
    );
  }
}
