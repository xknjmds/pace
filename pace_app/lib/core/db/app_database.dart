import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/class_blocks_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/blocked_apps_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/finance_dao.dart';
import 'daos/calendar_events_dao.dart';
import 'daos/daily_logs_dao.dart';
import 'daos/focus_sessions_dao.dart';
import 'daos/inbox_dao.dart';
import 'daos/reminder_mutes_dao.dart';
import 'daos/scheduled_notifications_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tasks_dao.dart';
import 'daos/weekday_schedule_dao.dart';
import 'schema_versions.dart';
import 'tables.dart';
import 'uuid.dart';

export 'daos/class_blocks_dao.dart';
export 'daos/habits_dao.dart';
export 'daos/blocked_apps_dao.dart';
export 'daos/notes_dao.dart';
export 'daos/finance_dao.dart';
export 'daos/calendar_events_dao.dart';
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
    ClassBlocks,
    Habits,
    HabitLogs,
    BlockedApps,
    Notes,
    Expenses,
    Budgets,
    CalendarEvents,
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
    ClassBlocksDao,
    HabitsDao,
    BlockedAppsDao,
    NotesDao,
    FinanceDao,
    CalendarEventsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [now] supplies the UTC timestamp written to `updated_at`. Injectable so
  /// tests can assert exact values.
  AppDatabase(super.executor, {DateTime Function()? now})
    : now = now ?? _utcNow;

  /// Opens the on-device database file. On the web it lives in the
  /// browser's storage, run by web/sqlite3.wasm and web/drift_worker.js
  /// (regenerate both with tool/build_web_db.sh after upgrading drift).
  ///
  /// On desktop the file goes in the per-app data folder (for example
  /// ~/.local/share/com.el.pace on Linux) rather than drift's default, the
  /// user's Documents folder. Android keeps its default, which is already
  /// private to the app.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'pace',
      native: DriftNativeOptions(
        databaseDirectory: _isDesktop ? getApplicationSupportDirectory : null,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  final DateTime Function() now;

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  int get schemaVersion => 6;

  /// Schema history. Never edit a released step (CLAUDE.md rule 8); add one,
  /// then regenerate: `drift_dev schema dump`, then `schema steps` into
  /// schema_versions.dart and `schema generate` into test/core/db/generated.
  ///
  /// - v1 (M1): `settings`
  /// - v2 (M3): every other table in the PLAN.md data model
  /// - v3 (M7): `settings.capture_shortcut_enabled`
  /// - v4 (M8): `focus_sessions.ended_at`
  /// - v5 (M9): settings for weekend leeway and the gradual wake shift
  /// - v6 (v2): class blocks, habits, blocked apps, notes, finance and
  ///   calendar tables; settings for the verse, currency, gate and calendar;
  ///   `tasks.submitted_at`
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Each step runs against the schema frozen at its version
    // (schema_versions.dart, generated from drift_schemas/), so a table
    // created in an early step never already has a later step's columns.
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        for (final table in <TableInfo<Table, Object>>[
          schema.weekdaySchedules,
          schema.tasks,
          schema.inboxItems,
          schema.dailyLogs,
          schema.focusSessions,
          schema.scheduledNotifications,
          schema.reminderMutes,
        ]) {
          await m.createTable(table);
        }
      },
      from2To3: (m, schema) async {
        await m.addColumn(
          schema.settings,
          schema.settings.captureShortcutEnabled,
        );
      },
      from3To4: (m, schema) async {
        await m.addColumn(schema.focusSessions, schema.focusSessions.endedAt);
        // Sessions from before v4 are history, not live timers.
        await customStatement(
          'UPDATE focus_sessions SET ended_at = started_at '
          'WHERE ended_at IS NULL',
        );
      },
      from4To5: (m, schema) async {
        final s = schema.settings;
        for (final column in [
          s.weekendLeewayMinutes,
          s.wakeGoalMinutes,
          s.wakeShiftFromMinutes,
          s.wakeShiftStartDate,
          s.wakeShiftStepMinutes,
          s.wakeShiftEveryDays,
        ]) {
          await m.addColumn(s, column);
        }
      },
      from5To6: (m, schema) async {
        for (final table in <TableInfo<Table, Object>>[
          schema.classBlocks,
          schema.habits,
          schema.habitLogs,
          schema.blockedApps,
          schema.notes,
          schema.expenses,
          schema.budgets,
          schema.calendarEvents,
        ]) {
          await m.createTable(table);
        }
        final s = schema.settings;
        for (final column in [
          s.verseEnabled,
          s.currencyCode,
          s.gateEnabled,
          s.morningLockEnabled,
          s.windDownLockEnabled,
          s.unlockMinutes,
          s.calendarSyncedAt,
        ]) {
          await m.addColumn(s, column);
        }
        await m.addColumn(schema.tasks, schema.tasks.submittedAt);
      },
    ),
    beforeOpen: (_) => settingsDao.ensureRow(),
  );
}
