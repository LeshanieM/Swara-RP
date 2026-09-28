import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/features/concomitant/presentation/widgets/video_analysis_ui.dart';

const double _labelWidth = 104;

/// Event timeline drawn from the real event timestamps in the results.
/// Pick a technology, filter behaviors, tap a bar to inspect an event.
class VideoTimelineScreen extends ConsumerStatefulWidget {
  final String analysisId;
  const VideoTimelineScreen({super.key, required this.analysisId});

  @override
  ConsumerState<VideoTimelineScreen> createState() => _VideoTimelineScreenState();
}

class _VideoTimelineScreenState extends ConsumerState<VideoTimelineScreen> {
  String? _eventBehavior;
  int? _eventIndex;

  void _clearEvent() {
    _eventBehavior = null;
    _eventIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(videoAnalysisResultsProvider(widget.analysisId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Event timeline')),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 1000,
          child: async.when(
            loading: () => const SwaraLoadingWidget(message: 'Loading analysis results...'),
            error: (e, _) => SwaraErrorWidget(
              message: VideoAnalysisException.from(e).message,
              onRetry: () => ref.invalidate(videoAnalysisResultsProvider(widget.analysisId)),
            ),
            data: (data) => data.hasResults
                ? _content(data)
                : const SwaraEmptyState(title: 'No results are available.', icon: Icons.inbox_outlined),
          ),
        ),
      ),
    );
  }

  Widget _content(VideoAnalysisResults data) {
    final id = widget.analysisId;
    final techs = data.technologies;
    final chosen = ref.watch(selectedTechnologyProvider(id));
    final tech = data.byKey(chosen ?? '') ??
        techs.firstWhere((t) => t.isCompleted, orElse: () => techs.first);
    final allKeys = data.behaviorKeys;
    final visible = ref.watch(selectedBehaviorsProvider(id)) ?? allKeys.toSet();
    final duration = data.durationSeconds;

    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      Text('Technology', style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.xs),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
        for (final t in techs)
          ChoiceChip(
            avatar: t.isCompleted ? null : Icon(t.status.icon, size: 16, color: t.status.color),
            label: Text(t.name),
            selected: t.key == tech.key,
            onSelected: (_) {
              ref.read(selectedTechnologyProvider(id).notifier).state = t.key;
              setState(_clearEvent);
            },
          ),
      ]),
      const SizedBox(height: AppSpacing.md),
      if (!tech.isCompleted)
        SwaraCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(tech.status.icon, color: tech.status.color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${tech.name}: technology ${tech.status.label.toLowerCase()}.\n'
                'Reason: ${humanizeReason(tech.reason)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
              ),
            ),
          ]),
        )
      else ...[
        Row(children: [
          Expanded(child: Text('Behaviors', style: AppTextStyles.label)),
          TextButton(
            onPressed: () {
              ref.read(selectedBehaviorsProvider(id).notifier).state = allKeys.toSet();
              setState(_clearEvent);
            },
            child: const Text('All'),
          ),
          TextButton(
            onPressed: () {
              ref.read(selectedBehaviorsProvider(id).notifier).state = <String>{};
              setState(_clearEvent);
            },
            child: const Text('None'),
          ),
        ]),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
          for (final k in allKeys)
            FilterChip(
              label: Text(behaviorLabel(k)),
              avatar: CircleAvatar(backgroundColor: behaviorColor(k), radius: 6),
              selected: visible.contains(k),
              onSelected: (on) {
                final next = {...visible};
                on ? next.add(k) : next.remove(k);
                ref.read(selectedBehaviorsProvider(id).notifier).state = next;
                setState(_clearEvent);
              },
            ),
        ]),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          const SwaraEmptyState(title: 'No behaviors selected', subtitle: 'Choose at least one behavior above.', icon: Icons.filter_list)
        else if (duration <= 0)
          const SwaraEmptyState(
            title: 'No events to display',
            subtitle: 'The video duration is unknown and no events were detected.',
            icon: Icons.timeline,
          )
        else
          _timelineCard(tech, [for (final k in allKeys) if (visible.contains(k)) k], duration),
        const SizedBox(height: AppSpacing.md),
        _eventCard(tech),
        const SizedBox(height: AppSpacing.md),
        const ResearchNote(
          'Bars show when each technology detected movement events. They are visual-feature events '
          'for research comparison, not confirmed secondary behaviors.',
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
    ]);
  }

  Widget _timelineCard(TechnologyResult tech, List<String> keys, double duration) {
    return SwaraCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(builder: (context, c) {
        final trackWidth = math.max(40.0, c.maxWidth - _labelWidth);
        final ticks = _ticks(duration, trackWidth);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SizedBox(width: _labelWidth),
            Expanded(
              child: CustomPaint(
                size: const Size(double.infinity, 20),
                painter: _AxisPainter(duration: duration, ticks: ticks),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          for (final k in keys) _behaviorRow(tech, k, duration, ticks),
        ]);
      }),
    );
  }

  Widget _behaviorRow(TechnologyResult tech, String key, double duration, List<double> ticks) {
    final b = tech.behavior(key);
    final color = behaviorColor(key);
    Widget track;
    if (!b.isSupported) {
      track = Text(
        b.support == BehaviorSupport.unsupported || b.support == BehaviorSupport.unknown
            ? 'Not supported by this technology'
            : b.support.label,
        style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
      );
    } else if (b.events.isEmpty) {
      track = Text('No events detected', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic));
    } else {
      track = LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTap(key, b.events, d.localPosition.dx, w, duration),
          child: CustomPaint(
            size: Size(w, 26),
            painter: _TrackPainter(
              events: b.events,
              duration: duration,
              color: color,
              ticks: ticks,
              selectedIndex: _eventBehavior == key ? _eventIndex : null,
            ),
          ),
        );
      });
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
          width: _labelWidth,
          child: Text(behaviorLabel(key), style: AppTextStyles.caption.copyWith(color: AppColors.text)),
        ),
        Expanded(child: SizedBox(height: 26, child: Align(alignment: Alignment.centerLeft, child: track))),
      ]),
    );
  }

  void _onTap(String key, List<BehaviorEvent> events, double dx, double width, double duration) {
    if (width <= 0 || duration <= 0) return;
    int? best;
    var bestDist = double.infinity;
    for (var i = 0; i < events.length; i++) {
      final x1 = events[i].startTime / duration * width;
      final x2 = math.max(events[i].endTime / duration * width, x1 + 4);
      final dist = dx < x1 ? x1 - dx : (dx > x2 ? dx - x2 : 0.0);
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    setState(() {
      if (best != null && bestDist <= 12) {
        _eventBehavior = key;
        _eventIndex = best;
      } else {
        _clearEvent();
      }
    });
  }

  Widget _eventCard(TechnologyResult tech) {
    final key = _eventBehavior;
    final idx = _eventIndex;
    if (key == null || idx == null) {
      return Text('Tap a bar to see the details of an event.', style: AppTextStyles.caption, textAlign: TextAlign.center);
    }
    final events = tech.behavior(key).events;
    if (idx >= events.length) return const SizedBox.shrink();
    final e = events[idx];
    return SwaraCard(
      color: AppColors.primaryWash,
      child: Row(children: [
        Container(width: 6, height: 44, decoration: BoxDecoration(color: behaviorColor(key), borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${behaviorLabel(key)} - event ${idx + 1} of ${events.length}', style: AppTextStyles.titleMedium),
            Text(
              '${e.startTime.toStringAsFixed(2)} s to ${e.endTime.toStringAsFixed(2)} s '
              '(duration ${e.duration.toStringAsFixed(2)} s)'
              '${e.peakValue != null ? ' - peak ${e.peakValue!.toStringAsFixed(3)}' : ''}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// "Nice" tick positions (seconds) for a time axis of [duration] over [width] px.
List<double> _ticks(double duration, double width) {
  if (duration <= 0) return const [0];
  final target = math.max(2, (width / 64).floor());
  final raw = duration / target;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final norm = raw / mag;
  final step = (norm <= 1 ? 1 : norm <= 2 ? 2 : norm <= 5 ? 5 : 10) * mag;
  final out = <double>[];
  for (var t = 0.0; t <= duration + 1e-9; t += step) {
    out.add(t);
  }
  return out;
}

String _tickLabel(double t) => t == t.roundToDouble() ? '${t.toInt()}s' : '${t.toStringAsFixed(1)}s';

class _AxisPainter extends CustomPainter {
  final double duration;
  final List<double> ticks;
  _AxisPainter({required this.duration, required this.ticks});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = AppColors.divider;
    for (final t in ticks) {
      final x = t / duration * size.width;
      canvas.drawLine(Offset(x, size.height - 5), Offset(x, size.height), line);
      final tp = TextPainter(
        text: TextSpan(text: _tickLabel(t), style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x - tp.width / 2).clamp(0.0, math.max(0.0, size.width - tp.width)).toDouble();
      tp.paint(canvas, Offset(dx, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _AxisPainter old) => old.duration != duration || old.ticks != ticks;
}

class _TrackPainter extends CustomPainter {
  final List<BehaviorEvent> events;
  final double duration;
  final Color color;
  final List<double> ticks;
  final int? selectedIndex;

  _TrackPainter({
    required this.events,
    required this.duration,
    required this.color,
    required this.ticks,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      Paint()..color = AppColors.surface,
    );
    final grid = Paint()..color = AppColors.divider.withValues(alpha: 0.7);
    for (final t in ticks) {
      final x = t / duration * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final fill = Paint()..color = color;
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final x1 = (e.startTime / duration * size.width).clamp(0.0, size.width).toDouble();
      final x2 = (e.endTime / duration * size.width).clamp(0.0, size.width).toDouble();
      final rect = Rect.fromLTWH(x1, 3, math.max(x2 - x1, 3), size.height - 6);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(rr, fill);
      if (i == selectedIndex) {
        canvas.drawRRect(
          rr.inflate(2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.text,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) =>
      old.events != events ||
      old.duration != duration ||
      old.color != color ||
      old.selectedIndex != selectedIndex ||
      old.ticks != ticks;
}
