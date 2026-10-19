import 'package:flutter/material.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';

/// Shared labels, colors and small widgets for the video-analysis screens.

// ---------------------------------------------------------------------------
// Playful, kid-friendly palette
// ---------------------------------------------------------------------------

const Map<String, String> _behaviorLabels = {
  'eye_blink': 'Blinking 👀',
  'lip_movement': 'Lip movement 👄',
  'jaw_movement': 'Jaw moves 😮',
  'facial_movement': 'Face moves 😊',
  'head_movement': 'Head turns 🙆',
};

const Map<String, Color> _behaviorColors = {
  'eye_blink': Color(0xFF3B82F6), // sky blue
  'lip_movement': Color(0xFFA855F7), // grape
  'jaw_movement': Color(0xFFEC4899), // bubblegum
  'facial_movement': Color(0xFF22C55E), // grass green
  'head_movement': Color(0xFFF59E0B), // sunny yellow
};

/// Friendly buddy icon per behavior (shown next to labels).
const Map<String, IconData> _behaviorIcons = {
  'eye_blink': Icons.remove_red_eye_rounded,
  'lip_movement': Icons.emoji_emotions_rounded,
  'jaw_movement': Icons.sentiment_satisfied_alt_rounded,
  'facial_movement': Icons.face_rounded,
  'head_movement': Icons.accessibility_new_rounded,
};

String behaviorLabel(String key) {
  final known = _behaviorLabels[key];
  if (known != null) return known;
  final t = key.replaceAll('_', ' ');
  return t.isEmpty ? key : t[0].toUpperCase() + t.substring(1);
}

IconData behaviorIcon(String key) =>
    _behaviorIcons[key] ?? Icons.auto_awesome_rounded;

Color behaviorColor(String key) => _behaviorColors[key] ?? AppColors.primary;

/// Lower-case noun used in summaries: "5 eye blinking events".
String behaviorEventsText(String key, int n) =>
    '${behaviorLabel(key)}: $n ${n == 1 ? 'event' : 'events'}';

String fmtSeconds(double? v, {int digits = 2}) =>
    v == null ? '-' : '${v.toStringAsFixed(digits)} s';

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
/// readable, friendly text, keeping any detail after the colon.
String humanizeReason(String? reason) {
  if (reason == null || reason.isEmpty) return 'Everything looks fine! 🌟';
  const codes = {
    'dependency_not_installed': 'Needs a helper tool installed',
    'model_unavailable': 'The magic model is not ready yet',
    'executable_not_found': 'Could not find the program',
    'runtime_error': 'Something went wrong while running',
    'unsupported_platform': 'This device cannot do this yet',
    'technology_does_not_provide_this_feature':
        'This feature is not available here',
  };
  final idx = reason.indexOf(':');
  final code = idx == -1 ? reason.trim() : reason.substring(0, idx).trim();
  final detail = idx == -1 ? '' : reason.substring(idx + 1).trim();
  final label = codes[code];
  if (label == null) return reason;
  return detail.isEmpty ? label : '$label ($detail)';
}

// ---------------------------------------------------------------------------
// Status presentation
// ---------------------------------------------------------------------------

extension TechStatusUi on TechStatus {
  String get label => switch (this) {
        TechStatus.waiting => 'Waiting 🕐',
        TechStatus.processing => 'Working 🔄',
        TechStatus.completed => 'All done! 🎉',
        TechStatus.unavailable => 'Not here 🙈',
        TechStatus.failed => 'Oops! 😅',
        TechStatus.unknown => 'Hmm? 🤔',
      };

  IconData get icon => switch (this) {
        TechStatus.waiting => Icons.hourglass_empty_rounded,
        TechStatus.processing => Icons.autorenew_rounded,
        TechStatus.completed => Icons.celebration_rounded,
        TechStatus.unavailable => Icons.sentiment_dissatisfied_rounded,
        TechStatus.failed => Icons.error_rounded,
        TechStatus.unknown => Icons.help_outline_rounded,
      };

  Color get color => switch (this) {
        TechStatus.waiting => const Color(0xFF94A3B8),
        TechStatus.processing => const Color(0xFF3B82F6),
        TechStatus.completed => const Color(0xFF22C55E),
        TechStatus.unavailable => const Color(0xFFF59E0B),
        TechStatus.failed => const Color(0xFFEF4444),
        TechStatus.unknown => const Color(0xFF94A3B8),
      };
}

extension BehaviorSupportUi on BehaviorSupport {
  String get label => switch (this) {
        BehaviorSupport.supported => 'Yes! 👍',
        BehaviorSupport.unsupported => 'Nope 🙅',
        BehaviorSupport.unavailable => 'Not now 🙈',
        BehaviorSupport.error => 'Oops 😅',
        BehaviorSupport.unknown => 'Unsure 🤔',
      };

  IconData get icon => switch (this) {
        BehaviorSupport.supported => Icons.thumb_up_rounded,
        BehaviorSupport.unsupported => Icons.thumb_down_rounded,
        BehaviorSupport.unavailable => Icons.visibility_off_rounded,
        BehaviorSupport.error => Icons.error_rounded,
        BehaviorSupport.unknown => Icons.help_outline_rounded,
      };

  Color get color => switch (this) {
        BehaviorSupport.supported => const Color(0xFF22C55E),
        BehaviorSupport.unsupported => const Color(0xFF94A3B8),
        BehaviorSupport.unavailable => const Color(0xFFF59E0B),
        BehaviorSupport.error => const Color(0xFFEF4444),
        BehaviorSupport.unknown => const Color(0xFF94A3B8),
      };
}

/// Status icon; a bouncy spinner while processing.
class TechStatusIcon extends StatelessWidget {
  final TechStatus status;
  final double size;
  const TechStatusIcon(this.status, {super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    if (status == TechStatus.processing) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFF3B82F6),
          strokeCap: StrokeCap.round,
        ),
      );
    }
    return Icon(status.icon, color: status.color, size: size);
  }
}

/// Rounded, colorful status pill with emoji-friendly styling.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly info banner used for research disclaimers — soft, rounded, warm.
class ResearchNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const ResearchNote(
    this.text, {
    super.key,
    this.icon = Icons.lightbulb_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6), // warm cream
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD98A), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7B8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFB45309)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF7C4A03),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Playful section title with a little colored dot.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFA855F7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Centers content and caps its width so screens read well on tablets/web.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

EdgeInsets videoPagePadding(BuildContext context) => EdgeInsets.all(
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
    );

// ---------------------------------------------------------------------------
// Friendly buddy widgets you can drop into screens
// ---------------------------------------------------------------------------

/// A big, tappable, rounded card with a soft colored background.
/// Use it for behavior cards, tech cards, etc.
class FriendlyCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const FriendlyCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final bg = color?.withValues(alpha: 0.12) ?? Colors.white;
    final border = color?.withValues(alpha: 0.30) ?? const Color(0xFFE2E8F0);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// A circular, colorful icon badge — great for list tiles and headers.
class BuddyBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const BuddyBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// A celebratory empty/completion state with a big emoji.
class FriendlyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;
  const FriendlyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                height: 1.4,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}