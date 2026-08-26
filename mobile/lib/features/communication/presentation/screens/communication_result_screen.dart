import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class CommunicationResultScreen extends StatefulWidget {
  const CommunicationResultScreen({super.key});

  @override
  State<CommunicationResultScreen> createState() => _CommunicationResultScreenState();
}

class _CommunicationResultScreenState extends State<CommunicationResultScreen> {
  int _viewMode = 0; // 0 = Child View, 1 = Clinician View

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c4Gradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Mode Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _viewMode = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _viewMode == 0 ? AppColors.ctaOrange : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Text('🧒 Child View', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _viewMode = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _viewMode == 1 ? AppColors.ctaOrange : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Text('🩺 Clinician Analysis', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_viewMode == 0) _buildChildView() else _buildClinicianDashboard(),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Return to Home Quest', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.softYellow, shape: BoxShape.circle),
          child: const Text('🌱', style: TextStyle(fontSize: 60)),
        ),
        const SizedBox(height: 16),
        const Text('Great Work! 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text('ගොඩක් හොඳයි!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.softYellow)),
        const SizedBox(height: 6),
        const Text(
          'You practiced speaking in different situations today.\nඅද ඔයා විවිධ අවස්ථාවල කතා කරලා පුහුණුවුණා.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
          child: const Column(
            children: [
              _ChildStatRow(icon: Icons.timer, label: 'Time Spoken', value: '1 min 20 sec'),
              Divider(height: 24),
              _ChildStatRow(icon: Icons.chat, label: 'Topic Completed', value: 'Topic 1 — At School'),
              Divider(height: 24),
              _ChildStatRow(icon: Icons.star, label: 'Spontaneous Practice', value: 'Completed! 🌟'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicianDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment_outlined, color: AppColors.jewelTeal, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Real-Life Communication Skills Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                    Text('Component 3 (Structured) vs Component 4 (Spontaneous)', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Generalization Status Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.softYellow.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.insights, color: AppColors.jewelEmerald),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generalization Status', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    Text('Developing Generalization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Communication Strengths', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.jewelEmerald)),
          const SizedBox(height: 6),
          _bulletPoint('Maintains conversation topic effectively'),
          _bulletPoint('Responds appropriately to real-life prompts'),
          _bulletPoint('Uses familiar vocabulary comfortably'),

          const SizedBox(height: 16),
          const Text('Areas to Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.coralRed)),
          const SizedBox(height: 6),
          _bulletPoint('Takes longer to initiate responses in spontaneous mode'),
          _bulletPoint('Increased pause duration during unfamiliar topics'),
          _bulletPoint('Fluency Gap: Slight disruption increase in spontaneous speech'),

          const Divider(height: 24),
          const Text('Structured vs Spontaneous Comparison', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 10),
          _compBar('Fluency', 'Comp 3: 88%', 'Comp 4: 74%'),
          _compBar('Speech Rate', 'Comp 3: 135 SPM', 'Comp 4: 110 SPM'),
          _compBar('Response Length', 'Comp 3: Long', 'Comp 4: Moderate'),
          _compBar('Topic Maintenance', 'Comp 3: 95%', 'Comp 4: 85%'),

          const Divider(height: 24),
          const Text('Clinician Decision Support', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.jewelNavy.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: const Text(
              '"The child demonstrated stronger fluency during structured activities but showed increased pauses during spontaneous speaking. Additional practice with spontaneous conversation may be useful."',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.text))),
        ],
      ),
    );
  }

  Widget _compBar(String label, String c3, String c4) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(c3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.jewelEmerald))),
                const Text(' vs ', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                Expanded(child: Text(c4, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ctaOrange))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ChildStatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ctaOrange, size: 24),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.jewelEmerald)),
      ],
    );
  }
}
