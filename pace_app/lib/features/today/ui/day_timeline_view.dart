import 'package:flutter/material.dart';

import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/time/local_time.dart';
import '../domain/day_timeline.dart';

/// The colour family of each kind of block.
PastelKind pastelFor(TimelineKind kind) => switch (kind) {
  TimelineKind.wake || TimelineKind.eat => PastelKind.morning,
  TimelineKind.leave || TimelineKind.classStart => PastelKind.leave,
  TimelineKind.deadline => PastelKind.deadline,
  TimelineKind.windDown || TimelineKind.bed => PastelKind.evening,
};

IconData iconFor(TimelineKind kind) => switch (kind) {
  TimelineKind.wake => Icons.wb_sunny_rounded,
  TimelineKind.eat => Icons.restaurant_rounded,
  TimelineKind.leave => Icons.directions_walk_rounded,
  TimelineKind.classStart => Icons.school_rounded,
  TimelineKind.deadline => Icons.assignment_rounded,
  TimelineKind.windDown => Icons.nights_stay_rounded,
  TimelineKind.bed => Icons.bedtime_rounded,
};

/// Today as soft time blocks on a rail, with a "now" line between what
/// is behind and what is ahead. Done blocks get a check and step back;
/// blocks not done are just still there.
class DayTimelineView extends StatelessWidget {
  const DayTimelineView({
    super.key,
    required this.entries,
    required this.now,
    this.onTapDeadline,
  });

  final List<TimelineEntry> entries;
  final DateTime now;
  final ValueChanged<String>? onTapDeadline;

  @override
  Widget build(BuildContext context) {
    final split = nowIndex(entries, now);
    return Column(
      children: [
        for (var i = 0; i <= entries.length; i++) ...[
          if (i == split) _NowLine(now: now),
          if (i < entries.length)
            _Block(
              key: ValueKey('timeline-${entries[i].kind.name}-$i'),
              entry: entries[i],
              first: i == 0,
              last: i == entries.length - 1,
              onTap: entries[i].taskId == null || onTapDeadline == null
                  ? null
                  : () => onTapDeadline!(entries[i].taskId!),
            ),
        ],
      ],
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: const ValueKey('timeline-now'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: ShapeDecoration(
              color: scheme.primary,
              shape: const StadiumBorder(),
            ),
            child: Text(
              LocalTime.of(now.hour, now.minute).format24(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    super.key,
    required this.entry,
    required this.first,
    required this.last,
    this.onTap,
  });

  final TimelineEntry entry;
  final bool first;
  final bool last;
  final VoidCallback? onTap;

  static const _timeWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pastel = PacePastels.of(context).forKind(pastelFor(entry.kind));
    final done = entry.done;
    final time = LocalTime.of(entry.at.hour, entry.at.minute).format24();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                time,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          // The rail: a soft line with a dot per block.
          SizedBox(
            width: 20,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: first ? 22 : 0,
                  bottom: last ? null : 0,
                  height: last ? 22 : null,
                  child: Container(width: 2, color: scheme.outlineVariant),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AnimatedContainer(
                    duration: PaceMotion.standard,
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? scheme.primary : scheme.surface,
                      border: Border.all(
                        color: done ? scheme.primary : pastel.ink,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AnimatedOpacity(
                duration: PaceMotion.standard,
                opacity: done ? .6 : 1,
                child: Material(
                  color: pastel.fill,
                  borderRadius: BorderRadius.circular(PaceRadius.m),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest.withValues(
                                alpha: .75,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              iconFor(entry.kind),
                              size: 19,
                              color: pastel.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSurface,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (done)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: scheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
