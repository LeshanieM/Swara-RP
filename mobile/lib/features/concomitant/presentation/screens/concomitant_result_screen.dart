import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  const ConcomitantResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.go('/'),
        ),
        title: const Column(
          children: [
            Text('Physical Behavior Analysis', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('ශාරීරික හැසිරීම් විශ්ලේෂණය', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverallScore(),
              const SizedBox(height: 24),
              _buildIndividualResults(),
              const SizedBox(height: 24),
              _buildTimeline(),
              const SizedBox(height: 24),
              _buildScoreSummary(),
              const SizedBox(height: 24),
              _buildClinicianSummary(),
              const SizedBox(height: 32),
              
              // Finish Button
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScore() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 0.72,
                  strokeWidth: 12,
                  backgroundColor: AppColors.primaryWash,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('72', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
                  Text('/ 100', style: TextStyle(fontSize: 16, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Physical Behavior Indicator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const Text('ශාරීරික හැසිරීම් දර්ශකය', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryWash.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: const Column(
              children: [
                Text(
                  'This score summarizes the physical behavior indicators detected in the uploaded video.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'මෙම ලකුණු වීඩියෝවේ හඳුනාගත් ශාරීරික හැසිරීම් දර්ශක සාරාංශ කරයි.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIndividualResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detected Behaviors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
        const SizedBox(height: 12),
        _buildDetectionCard(
          icon: Icons.person,
          titleEn: 'Head Movements',
          titleSi: 'හිස චලනයන්',
          mainValue: '18 detected',
          details: ['Total occurrences: 18', 'Average movement intensity: 42%', 'Maximum movement intensity: 71%', 'Duration involved: 8.4 sec'],
        ),
        _buildDetectionCard(
          icon: Icons.visibility,
          titleEn: 'Eye Blinks',
          titleSi: 'ඇස් පිළිසැරීම',
          mainValue: '27 detected',
          details: ['Total blinks: 27', 'Blinks per minute: 15.9', 'Average blink interval: 3.8 sec'],
          note: 'Detected eye-blink events / හඳුනාගත් ඇස් පිළිසැරීම්',
        ),
        _buildDetectionCard(
          icon: Icons.face,
          titleEn: 'Facial Movement',
          titleSi: 'මුහුණේ චලනය',
          mainValue: '12 events detected',
          details: ['Detected events: 12', 'Average intensity: 36%', 'Maximum intensity: 68%'],
          warning: 'Facial movement patterns may have multiple causes and should be interpreted by an SLP.\nමුහුණේ චලන රටාවන්ට විවිධ හේතු තිබිය හැකි බැවින් SLP වරයෙකු විසින් ඒවා අර්ථකථනය කළ යුතුය.',
        ),
        _buildDetectionCard(
          icon: Icons.back_hand,
          titleEn: 'Hand Movements',
          titleSi: 'අත් චලනයන්',
          mainValue: '9 events detected',
          details: ['Total events: 9', 'Average duration: 1.2 sec', 'Average intensity: 31%'],
        ),
        _buildDetectionCard(
          icon: Icons.accessibility_new,
          titleEn: 'Body Movements',
          titleSi: 'ශරීර චලනයන්',
          mainValue: '6 events detected',
          details: ['Total events: 6', 'Average duration: 2.1 sec', 'Movement intensity: 45%'],
        ),
      ],
    );
  }

  Widget _buildDetectionCard({
    required IconData icon,
    required String titleEn,
    required String titleSi,
    required String mainValue,
    required List<String> details,
    String? note,
    String? warning,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleEn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                    Text(titleSi, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
              Text(mainValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text(d, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
              ],
            ),
          )),
          if (note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.mintGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(note, style: const TextStyle(fontSize: 11, color: AppColors.mintGreen, fontWeight: FontWeight.w600)),
            ),
          ],
          if (warning != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warning, style: const TextStyle(fontSize: 11, color: Colors.orange))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Behavior Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const Text('හැසිරීම් කාලරේඛාව', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              Text('01:42', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              _buildTimelineMarker(0.14, Colors.blue), // 00:14 Head
              _buildTimelineMarker(0.18, Colors.green), // 00:18 Blink
              _buildTimelineMarker(0.30, Colors.orange), // 00:31 Facial
              _buildTimelineMarker(0.46, Colors.blue), // 00:47 Head
              _buildTimelineMarker(0.62, Colors.purple), // 01:03 Hand
            ],
          ),
          const SizedBox(height: 16),
          // Selected point mock
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Head Movement / හිස චලනය', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDeep)),
                      Text('Intensity: 61% (තීව්රතාව)', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
                Text('00:47', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(double percent, Color color) {
    return Positioned(
      left: percent * 300, // Roughly layout width
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      ),
    );
  }

  Widget _buildScoreSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Physical Behavior Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const Text('ශාරීරික හැසිරීම් සාරාංශය', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 16),
          _buildSummaryBar('Head movement', 0.25, Colors.blue),
          _buildSummaryBar('Eye-blink events', 0.20, Colors.green),
          _buildSummaryBar('Facial movement', 0.25, Colors.orange),
          _buildSummaryBar('Hand movement', 0.15, Colors.purple),
          _buildSummaryBar('Body movement', 0.15, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text))),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildClinicianSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.softYellow),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analysis Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          Text('විශ්ලේෂණ සාරාංශය', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          SizedBox(height: 12),
          Text(
            'The video analysis detected several physical movement events during speech. Head movements and eye-blink events were the most frequently detected behaviors.',
            style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            'වීඩියෝ විශ්ලේෂණයේදී කථනය අතරතුර ශාරීරික චලන සිදුවීම් කිහිපයක් හඳුනාගෙන ඇත. වැඩි වශයෙන් හඳුනාගත් හැසිරීම් ලෙස හිස චලනයන් සහ ඇස් පිළිසැරීම් දැක්විය හැක.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4),
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 8),
          Text('Clinical Note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text)),
          SizedBox(height: 4),
          Text(
            'These results are intended to support clinician review and should not be used as a standalone diagnosis.\nමෙම ප්රතිඵල වෛද්ය/SLP ඇගයීම සඳහා සහායක් ලෙස පමණක් භාවිත කළ යුතු අතර ස්වාධීන රෝග විනිශ්චයක් ලෙස භාවිත නොකළ යුතුය.',
            style: TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
