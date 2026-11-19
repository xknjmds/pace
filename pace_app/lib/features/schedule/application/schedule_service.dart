import '../../../core/energy/low_energy.dart';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/home_widget/home_widget_bridge.dart';
import '../domain/schedule_parser.dart';

/// Saves class blocks and keeps the routine and the today's-classes widget
/// in step with them.
class ScheduleService {
  ScheduleService({
    required this.db,
    required this.widget,
    required this.resyncReminders,
    required this.now,
  });

  final AppDatabase db;
  final HomeWidgetBridge widget;
  final Future<void> Function() resyncReminders;
  final DateTime Function() now;

  /// Saves the reviewed import. Earlier image-sourced blocks are replaced;
  /// hand-typed ones stay. [useAsFirstClass] holds the weekdays whose
  /// earliest imported block the owner chose to make the first class time.
  Future<void> confirmImport(
    List<CandidateBlock> blocks, {
    required Set<int> useAsFirstClass,
  }) async {
    final complete = blocks.where((b) => b.complete).toList();
    await db.classBlocksDao.replaceImported([
      for (final b in complete)
        ClassBlocksCompanion.insert(
          weekday: b.weekday!,
          subject: b.subject.trim(),
          startMinutes: b.start!,
          endMinutes: b.end!,
          room: Value(b.room),
          updatedAt: now().toUtc(),
        ),
    ]);
    final earliest = earliestStartByWeekday(complete);
    for (final weekday in useAsFirstClass) {
      final start = earliest[weekday];
      if (start == null) continue;
      final row = await db.weekdayScheduleDao.getFor(weekday);
      await db.weekdayScheduleDao.upsert(
        weekday: weekday,
        firstClassMinutes: start,
        commuteMinutes: row?.commuteMinutes ?? 30,
        prepMinutes: row?.prepMinutes ?? 30,
      );
    }
    if (useAsFirstClass.isNotEmpty) await resyncReminders();
    await publishWidget();
  }

  Future<void> add({
    required int weekday,
    required String subject,
    required int start,
    required int end,
    String? room,
  }) async {
    await db.classBlocksDao.add(
      weekday: weekday,
      subject: subject,
      startMinutes: start,
      endMinutes: end,
      room: room,
    );
    await publishWidget();
  }

  Future<void> edit(ClassBlock block) async {
    await db.classBlocksDao.edit(block);
    await publishWidget();
  }

  Future<void> remove(String id) async {
    await db.classBlocksDao.remove(id);
    await publishWidget();
  }

  /// Undoes [remove].
  Future<void> restore(String id) async {
    await db.classBlocksDao.restore(id);
    await publishWidget();
  }

  /// Sends the week's blocks, the next week of calendar events and the
  /// low-energy flag to the widget.
  Future<void> publishWidget() async {
    final settings = await db.settingsDao.get();
    final blocks = await db.classBlocksDao.getAll();
    final t = now();
    final events = await db.calendarEventsDao.between(
      t.subtract(const Duration(days: 1)),
      t.add(const Duration(days: 8)),
    );
    await widget.publishSchedule(
      scheduleWidgetJson(
        blocks: blocks,
        events: events,
        lowEnergy: settings.lowEnergyAt(t),
      ),
    );
  }
}

/// The widget's data: classes by weekday (minutes since midnight) and
/// events as epoch milliseconds. Read by PaceScheduleWidgetProvider.kt.
String scheduleWidgetJson({
  required List<ClassBlock> blocks,
  required List<CalendarEvent> events,
  required bool lowEnergy,
}) => jsonEncode({
  'lowEnergy': lowEnergy,
  'classes': {
    for (var d = 1; d <= 7; d++)
      '$d': [
        for (final b in blocks)
          if (b.weekday == d)
            {
              's': b.startMinutes,
              'e': b.endMinutes,
              't': b.subject,
              if (b.room != null) 'r': b.room,
            },
      ],
  },
  'events': [
    for (final e in events)
      if (!e.allDay)
        {
          's': e.startAt.millisecondsSinceEpoch,
          'e': e.endAt.millisecondsSinceEpoch,
          't': e.title,
        },
  ],
});
