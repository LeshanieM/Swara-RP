import 'package:flutter/material.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';

/// Shared labels, colors and small widgets for the video-analysis screens.

const Map<String, String> _behaviorLabels = {
  'eye_blink': 'Eye blinking',
  'lip_movement': 'Lip movement',
  'jaw_movement': 'Jaw movement',
  'facial_movement': 'Facial movement',
  'head_movement': 'Head movement',
  'hand_movement': 'Hand movement',
  'arm_movement': 'Arm movement',
};

const Map<String, Color> _behaviorColors = {
  'eye_blink': Color(0xFF2563EB),
  'lip_movement': Color(0xFF7C3AED),
  'jaw_movement': Color(0xFFDB2777),
  'facial_movement': Color(0xFF059669),
  'head_movement': Color(0xFFD97706),
  'hand_movement': Color(0xFFDC2626),
  'arm_movement': Color(0xFF0891B2),
};

String behaviorLabel(String key) {
  final known = _behaviorLabels[key];
  if (known != null) return known;
  final t = key.replaceAll('_', ' ');
  return t.isEmpty ? key : t[0].toUpperCase() + t.substring(1);
}

Color behaviorColor(String key) => _behaviorColors[key] ?? AppColors.primary;

/// Lower-case noun used in summaries: "5 eye blinking events".
String behaviorEventsText(String key, int n) =>
    '${behaviorLabel(key)}: $n ${n == 1 ? 'event' : 'events'}';

String fmtSeconds(double? v, {int digits = 2}) => v == null ? '-' : '${v.toStringAsFixed(digits)} s';

String fmtNum(num? v, {int digits = 2}) {
  if (v == null) return '-';
  if (v is int) return '$v';
  return v.toStringAsFixed(digits);
}

String fmtBytes(int b) {
  if (b >= 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '$b B';
}

String fmtClock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

String fmtDate(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

/// Turns backend reason codes ("dependency_not_installed: mediapipe") into
/// readable text, keeping any detail after the colon.
String humanizeReason(String? reason) {
  if (reason == null || reason.isEmpty) return 'No reason was reported.';
  const codes = {
    'dependency_not_installed': 'Required dependency is not installed',
    'model_unavailable': 'Model not installed',
    'executable_not_found': 'Executable not found',
    'runtime_error': 'Runtime error',
    'unsupported_platform': 'Unsupported platform',
    'technology_does_not_provide_this_feature': 'Not provided by this technology',
  };
  final idx = reason.indexOf(':');
  final code = idx == -1 ? reason.trim() : reason.substring(0, idx).trim();
  final detail = idx == -1 ? '' : reason.substring(idx + 1).trim();
  final label = codes[code];
  if (label == null) return reason;
  return detail.isEmpty ? label : '$label - $detail';
}

// ---------------------------------------------------------------------------
// Status presentation
// ---------------------------------------------------------------------------

extension TechStatusUi on TechStatus {
  String get label => switch (this) {
        TechStatus.waiting => 'Waiting',
        TechStatus.processing => 'Processing',
        TechStatus.completed => 'Completed',
        TechStatus.unavailable => 'Unavailable',
        TechStatus.failed => 'Failed',
        TechStatus.unknown => 'Unknown',
      };

  IconData get icon => switch (this) {
        TechStatus.waiting => Icons.hourglass_empty_rounded,
        TechStatus.processing => Icons.sync_rounded,
        TechStatus.completed => Icons.check_circle_rounded,
        TechStatus.unavailable => Icons.warning_amber_rounded,
        TechStatus.failed => Icons.cancel_rounded,
        TechStatus.unknown => Icons.help_outline_rounded,
      };

  Color get color => switch (this) {
        TechStatus.waiting => AppColors.textLight,
        TechStatus.processing => AppColors.primary,
        TechStatus.completed => AppColors.success,
        TechStatus.unavailable => AppColors.warning,
        TechStatus.failed => AppColors.error,
        TechStatus.unknown => AppColors.textLight,
      };
}

extension BehaviorSupportUi on BehaviorSupport {
  String get label => switch (this) {
        BehaviorSupport.supported => 'Supported',
        BehaviorSupport.unsupported => 'Unsupported',
        BehaviorSupport.unavailable => 'Unavailable',
        BehaviorSupport.error => 'Failed',
        BehaviorSupport.unknown => 'Unknown',
      };

  IconData get icon => switch (this) {
        BehaviorSupport.supported => Icons.check_circle_rounded,
        BehaviorSupport.unsupported => Icons.remove_rounded,
        BehaviorSupport.unavailable => Icons.warning_amber_rounded,
        BehaviorSupport.error => Icons.cancel_rounded,
        BehaviorSupport.unknown => Icons.help_outline_rounded,
      };

  Color get color => switch (this) {
        BehaviorSupport.supported => AppColors.success,
        BehaviorSupport.unsupported => AppColors.textLight,
        BehaviorSupport.unavailable => AppColors.warning,
        BehaviorSupport.error => AppColors.error,
        BehaviorSupport.unknown => AppColors.textLight,
      };
}

/// Status icon; a spinner while processing.
class TechStatusIcon extends StatelessWidget {
  final TechStatus status;
  final double size;
  const TechStatusIcon(this.status, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    if (status == TechStatus.processing) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
    }
    return Icon(status.icon, color: status.color, size: size);
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillAll,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Small info banner used for research disclaimers.
class ResearchNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const ResearchNote(this.text, {super.key, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.primaryDeep),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.text))),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(children: [
        Expanded(child: Text(text, style: AppTextStyles.heading3)),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Centers content and caps its width so screens read well on tablets/web.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 760});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
