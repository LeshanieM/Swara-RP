import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class CommunicationReportScreen extends StatelessWidget {
  const CommunicationReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.groundRead,
      appBar: AppBar(
        title: const Text('භාෂා හා වචන විශ්ලේෂණය'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDeep,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfo(),
              const SizedBox(height: 32),
              _buildPersonalizedTaskSelection(),
              const SizedBox(height: 32),
              _buildSpeechSample(),
              const SizedBox(height: 32),
              _buildLanguageProfile(),
              const SizedBox(height: 32),
              _buildLexicalDiversity(),
              const SizedBox(height: 24),
              _buildMLUSection(),
              const SizedBox(height: 24),
              _buildSpeechFlowSection(),
              const SizedBox(height: 32),
              _buildPersonalizedInterpretation(),
              const SizedBox(height: 32),
              _buildObservationSummary(),
              const SizedBox(height: 32),
              _buildSessionComparison(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ස්වභාවික සිංහල කථන නියැදිය', style: AppTextStyles.heading2.copyWith(color: AppColors.textLight)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.mdAll,
            boxShadow: [
              BoxShadow(
                color: AppColors.divider,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow('දරුවාගේ අංකය', 'SW-8472 (රහස්‍ය)'),
              const Divider(),
              _buildInfoRow('සැසිය', '04'),
              const Divider(),
              _buildInfoRow('දිනය', '2024 නොවැම්බර් 14'),
              const Divider(),
              _buildInfoRow('කාර්යය', 'රූප පෙළක් ගැන කතාවක්'),
              const Divider(),
              _buildInfoRow('කාර්ය අංකය', 'TSK-PSN-02'),
              const Divider(),
              _buildInfoRow('විශ්ලේෂණ තත්ත්වය', '✅ සම්පූර්ණයි'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
          Text(value, style: AppTextStyles.heading3),
        ],
      ),
    );
  }

  Widget _buildSpeechSample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('කථන පිටපත', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“මගේ බල්ලාගේ නම ටොමී. එයා මාත් එක්ක සෙල්ලම් කරන්න ගොඩක් කැමතියි. අපි හැමදාම හවසට සෙල්ලම් කරනවා. එයා ගොඩක් හොඳයි.”',
                style: AppTextStyles.heading3.copyWith(
                  height: 1.6,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text('00:00 - 00:18', style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('භාෂා පැතිකඩ', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.primaryLight, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildProfileItem('වචන විවිධත්වය', 'භාවිත කළ වෙනස් වචන මනින ලදී.'),
              const Divider(height: 24),
              _buildProfileItem('ප්‍රකාශන දිග', 'එක් ප්‍රකාශනයක සාමාන්‍ය දිග මනින ලදී.'),
              const Divider(height: 24),
              _buildProfileItem('කථන වේගය', 'කථන වේගය මනින ලදී.'),
              const Divider(height: 24),
              _buildProfileItem('විරාම', 'විරාම ගණන සහ කාලය මනින ලදී.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(desc, style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLexicalDiversity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('වචන විවිධත්වය', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('NDW', '38', 'වෙනස් වචන ගණන')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('MATTR', '0.48', 'වචන විවිධත්ව අනුපාතය')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('VocD', '51', 'වචන මාලාවේ විවිධත්වය')),
          ],
        ),
      ],
    );
  }

  Widget _buildMLUSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('සාමාන්‍ය ප්‍රකාශන දිග', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryWash,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Column(
            children: [
              const Text('MLU', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
              const SizedBox(height: 8),
              const Text('3.5', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primaryDeep)),
              const SizedBox(height: 8),
              Text('විශ්ලේෂණය කළ ප්‍රකාශනවල සාමාන්‍ය දිග.', style: AppTextStyles.caption.copyWith(color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('කථන ප්‍රවාහය', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.divider,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildFlowRow('කථන වේගය', 'තත්පරයට වචන 2.8ක්', 0.6),
              const SizedBox(height: 16),
              _buildFlowRow('විරාම ගණන', 'විරාම 12ක්', 0.4),
              const SizedBox(height: 16),
              _buildFlowRow('සාමාන්‍ය විරාම කාලය', 'තත්පර 0.9ක්', 0.3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowRow(String label, String value, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
            Text(value, style: AppTextStyles.heading3),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: AppColors.surfaceRaised,
          color: AppColors.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildPersonalizedInterpretation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('භාෂා විශ්ලේෂණ සොයාගැනීම්', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('හඳුනාගත් භාෂා රටාව', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Text(
                'පෙර සැසියට සාපේක්ෂව මෙවර භාවිත කළ වෙනස් වචන ගණන සහ සාමාන්‍ය ප්‍රකාශන දිග වැඩි වී ඇත.',
                style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _buildTrendRow('NDW', '38', '45', true),
              _buildTrendRow('MATTR', '0.48', '0.54', true),
              _buildTrendRow('MLU', '3.1', '3.5', true),
              _buildTrendRow('VocD', '51', '57', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendRow(String label, String oldVal, String newVal, bool up) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: AppTextStyles.label)),
          Text('$oldVal → ', style: AppTextStyles.bodySmall),
          Text(newVal, style: AppTextStyles.label),
          const SizedBox(width: 8),
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: up ? AppColors.success : AppColors.error),
        ],
      ),
    );
  }

  Widget _buildObservationSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('භාෂා නිරීක්ෂණ', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('ස්වයංක්‍රීය නිරීක්ෂණය', style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• පෙර සැසියට වඩා විවිධ වචන භාවිත වී ඇත.\n'
                '• සාමාන්‍ය ප්‍රකාශන දිග සුළු වශයෙන් වැඩි වී ඇත.\n'
                '• කථන වේගය සැසිය පුරා ආසන්නව ස්ථාවරව පැවතුණි.',
                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'මෙම නිරීක්ෂණය කථන නියැදියෙන් ස්වයංක්‍රීයව සකස් කර ඇත. සුදුසුකම් ලත් කථන චිකිත්සකයෙකු එය සමාලෝචනය කළ යුතුය.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComparison() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('භාෂා ගමන\n(සැසි ප්‍රගතිය)', style: AppTextStyles.heading2),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('සැසි සැසඳීමේ පෙරහන විවෘත කළා')),
                  );
                },
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('සැසි සසඳන්න'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'සැසිය 1 → සැසිය 2 → සැසිය 3 → සැසිය 4\nNDW: 38 → 41 → 45 → 49',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('දක්නට ලැබුණු වෙනස:', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'පටිගත කළ සැසි අතර වෙනස් වචන භාවිතය වැඩි වන ප්‍රවණතාවක් පෙන්නුම් කළේය.',
            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTaskSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('පුද්ගලීකරණය කළ කාර්යය තෝරාගැනීම', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.primaryLight, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('පෙර සැසියේ පැතිකඩ', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              _buildProfileListItem('අංගය 1: කියවීමේදී පැකිළීම් ප්‍රමාණය ස්ථාවරයි.'),
              _buildProfileListItem('අංගය 2: සැලකිය යුතු ද්විතීයික හැසිරීම් හමු නොවීය.'),
              _buildProfileListItem('අංගය 3: හුස්ම ගැනීමේ පුහුණුව සාර්ථකව අවසන් කළා.'),
              _buildProfileListItem('අංගය 4 (පෙර): රූපයක් විස්තර කිරීමේදී විවිධ වචන භාවිත කළා.'),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text('යෝජිත කථන ක්‍රියාකාරකම', style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('රූප පෙළක් ගැන කතාවක්', style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDeep)),
                ],
              ),
              const SizedBox(height: 24),
              Text('තෝරාගැනීමට හේතුව', style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
              const SizedBox(height: 4),
              Text(
                '“This task was selected to obtain spontaneous narrative speech while maintaining a structured speaking context.”',
                style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.text))),
        ],
      ),
    );
  }

  void _showAlternativesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('වෙනත් ක්‍රියාකාරකම්', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primary),
                title: const Text('රූපයක් විස්තර කිරීම'),
                subtitle: const Text('වචන භාවිතය පුහුණු කිරීම'),
                trailing: const Icon(Icons.check_circle, color: AppColors.success),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('රූපයක් විස්තර කිරීම තෝරාගත්තා')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                title: const Text('නිදහස් කතාබහ'),
                subtitle: const Text('ස්වභාවික කථනය පුහුණු කිරීම'),
                trailing: const Icon(Icons.circle_outlined),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('නිදහස් කතාබහ තෝරාගත්තා')),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAssignSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              Text('ක්‍රියාකාරකම පවරා ඇත', style: AppTextStyles.heading2),
            ],
          ),
          content: Text(
            'ඊළඟ සැසිය සඳහා යෝජිත ක්‍රියාකාරකම දරුවාගේ මුල් පිටුවට සාර්ථකව පවරා ඇත.',
            style: AppTextStyles.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              child: const Text('මුල් පිටුවට යන්න'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalizedNextActivity() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ඊළඟට යෝජිත කථන ක්‍රියාකාරකම', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
            color: AppColors.surfaceRaised,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('යෝජනාව: කතාවක් නැවත කියන්න', style: AppTextStyles.heading3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('හේතුව:', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    'පෙර සැසිවලදී රූප විස්තර කිරීම සාර්ථක විය. තව ටිකක් විවෘත කතා ක්‍රියාකාරකමකින් ස්වභාවික වචන භාවිතය සහ ප්‍රකාශන නිරීක්ෂණය කළ හැකියි.',
                    style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showAlternativesBottomSheet(context),
                          child: const Text('වෙනත් ක්‍රියාකාරකම් බලන්න'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showAssignSuccessDialog(context),
                          child: const Text('ක්‍රියාකාරකම පවරන්න'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'කථන චිකිත්සක සමාලෝචනය සඳහා ස්වයංක්‍රීය යෝජනාවක්',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
