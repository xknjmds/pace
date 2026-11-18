import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/pace_section_card.dart';
import '../../calendar/application/calendar_providers.dart';
import '../application/schedule_providers.dart';
import '../domain/class_day.dart';

/// Today's classes and calendar events, with the one under way marked.
/// Low-energy mode keeps only what is now and what is next. Nothing shows
/// when the day has neither.
class TodayClassesCard extends ConsumerWidget {
  const TodayClassesCard({super.key, required this.now, this.onOpen});

  final DateTime now;
  final VoidCallback? onOpen;

  static String _hm(DateTime t) => LocalTime.of(t.hour, t.minute).format24();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(classBlocksProvider).value ?? const <ClassBlock>[];
    final events =
        ref.watch(eventsOnDayProvider(dateKey(now))).value ??
        const <CalendarEvent>[];
    final lowEnergy = ref.watch(lowEnergyProvider);
    final day = DateTime(now.year, now.month, now.day);
    final items = mergeDay(
      [
        for (final b in blocks)
          if (b.weekday == now.weekday)
            DayItem(
              title: b.subject,
              start: day.add(Duration(minutes: b.startMinutes)),
              end: day.add(Duration(minutes: b.endMinutes)),
              room: b.room,
            ),
      ],
      [
        for (final e in events)
          if (!e.allDay)
            DayItem(
              title: e.title,
              start: e.startAt.toLocal(),
              end: e.endAt.toLocal(),
              isEvent: true,
            ),
      ],
    );
    if (items.isEmpty) return const SizedBox.shrink();
    final nn = nowAndNext(items, now);
    final shown = lowEnergy
        ? [?nn.current, ?nn.next]
        : items.where((i) => i.end.isAfter(now) || i == nn.current).toList();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PaceSectionCard(
      key: const ValueKey('today-classes'),
      title: 'Classes today',
      icon: Icons.school_outlined,
      pastel: PastelKind.leave,
      action: onOpen == null
          ? null
          : TextButton(onPressed: onOpen, child: const Text('Week')),
      child: shown.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                'That is everything for today.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final i in shown)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4, right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: i == nn.current
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            '${_hm(i.start)}–${_hm(i.end)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        if (i.isEvent)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.event_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            [i.title, if (i.room != null) i.room].join(' · '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (i == nn.current)
                          Text('now', style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
