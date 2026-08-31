import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/communication_topic.dart';

class TopicScreen extends StatelessWidget {
  final CommunicationTopic topic;
  const TopicScreen({Key? key, required this.topic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Today\'s Challenge\nඅද අභියෝගය'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    topic.image,
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  topic.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  topic.sinhalaTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        topic.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.sinhalaDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Tell me:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'මට කියන්න:',
                  style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(topic.prompts.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blueAccent,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(topic.prompts[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(topic.sinhalaPrompts[index], style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.volume_up),
                        label: const Text('🔊 Listen\nඅහන්න', textAlign: TextAlign.center),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/c4/preparation');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'I\'m Ready\nමම සූදානම්',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
