import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/daily_logs_dao.dart';
import 'daos/focus_sessions_dao.dart';
import 'daos/inbox_dao.dart';
import 'daos/reminder_mutes_dao.dart';
import 'daos/scheduled_notifications_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tasks_dao.dart';
import 'daos/weekday_schedule_dao.dart';
import 'tables.dart';
import 'uuid.dart';

export 'daos/daily_logs_dao.dart';
export 'daos/focus_sessions_dao.dart';
export 'daos/inbox_dao.dart';
export 'daos/reminder_mutes_dao.dart';
export 'daos/scheduled_notifications_dao.dart';
export 'daos/settings_dao.dart';
export 'daos/tasks_dao.dart';
export 'daos/weekday_schedule_dao.dart';
export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Settings,
    WeekdaySchedules,
    Tasks,
    InboxItems,
    DailyLogs,
    FocusSessions,
    ScheduledNotifications,
    ReminderMutes,
  ],
  daos: [
    SettingsDao,
    WeekdayScheduleDao,
    TasksDao,
    InboxDao,
    DailyLogsDao,
    FocusSessionsDao,
    ScheduledNotificationsDao,
    ReminderMutesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [now] supplies the UTC timestamp written to `updated_at`. Injectable so
  /// tests can assert exact values.
  AppDatabase(super.executor, {DateTime Function()? now})
    : now = now ?? _utcNow;

  /// Opens the on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'pace'));

  final DateTime Function() now;

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  int get schemaVersion => 2;

  /// Schema history. Never edit a released step (CLAUDE.md rule 8); add one.
  ///
  /// - v1 (M1): `settings`
  /// - v2 (M3): every other table in the PLAN.md data model
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        for (final table in <TableInfo<Table, Object>>[
          weekdaySchedules,
          tasks,
          inboxItems,
          dailyLogs,
          focusSessions,
          scheduledNotifications,
          reminderMutes,
        ]) {
          await m.createTable(table);
        }
      }
    },
    beforeOpen: (_) => settingsDao.ensureRow(),
  );
}
