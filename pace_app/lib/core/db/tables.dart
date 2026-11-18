import 'dart:convert';

import 'package:drift/drift.dart';

import 'uuid.dart';

export '../notifications/reminder_draft.dart';
export '../time/date_key.dart';

/// Columns every table carries so a later sync layer can diff and merge rows
/// (CLAUDE.md rule 9). Rows are never hard-deleted: DAOs set [deletedAt] and
/// every read filters it out.
mixin SyncColumns on Table {
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Text UUID v4 primary key, generated on the device at insert time.
mixin UuidKey on Table {
  TextColumn get id => text().clientDefault(uuidV4)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single-row table (id = 1) holding the owner's preferences.
/// Times of day are minutes since midnight; durations are minutes.
class Settings extends Table with SyncColumns {
  IntColumn get id => integer()();
  IntColumn get targetWakeMinutes =>
      integer().withDefault(const Constant(6 * 60 + 30))();
  IntColumn get sleepTargetMinutes =>
      integer().withDefault(const Constant(8 * 60))();
  IntColumn get windDownLeadMinutes =>
      integer().withDefault(const Constant(45))();
  IntColumn get breakfastMinutes => integer().withDefault(const Constant(15))();
  IntColumn get lateThresholdMinutes =>
      integer().withDefault(const Constant(20))();
  BoolColumn get lowEnergyEnabled =>
      boolean().withDefault(const Constant(false))();

  /// v3: keep a "capture a thought" notification with an inline reply field.
  BoolColumn get captureShortcutEnabled =>
      boolean().withDefault(const Constant(true))();

  /// v5: how much later Saturday and Sunday wake may be (0 to 60).
  IntColumn get weekendLeewayMinutes =>
      integer().withDefault(const Constant(60))();

  /// v5: gradual wake shift. All null when no shift is under way: the wake
  /// time moves from [wakeShiftFromMinutes] toward [wakeGoalMinutes] by
  /// [wakeShiftStepMinutes] every [wakeShiftEveryDays] calendar days,
  /// counted from [wakeShiftStartDate] (`yyyy-MM-dd`).
  IntColumn get wakeGoalMinutes => integer().nullable()();
  IntColumn get wakeShiftFromMinutes => integer().nullable()();
  TextColumn get wakeShiftStartDate => text().nullable()();
  IntColumn get wakeShiftStepMinutes =>
      integer().withDefault(const Constant(15))();
  IntColumn get wakeShiftEveryDays =>
      integer().withDefault(const Constant(3))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per weekday ([DateTime.monday] to [DateTime.sunday]). A null
/// [firstClassMinutes] means no class that day.
class WeekdaySchedules extends Table with UuidKey, SyncColumns {
  IntColumn get weekday => integer()();
  IntColumn get firstClassMinutes => integer().nullable()();
  IntColumn get commuteMinutes => integer().withDefault(const Constant(30))();
  IntColumn get prepMinutes => integer().withDefault(const Constant(30))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {weekday},
  ];
}

enum TaskStatus { pending, submitted }

enum TaskSource { manual, classroom }

class Tasks extends Table with UuidKey, SyncColumns {
  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(const Constant('pending'))();
  TextColumn get source =>
      textEnum<TaskSource>().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Quick captures waiting to become a task or be discarded.
class InboxItems extends Table with UuidKey, SyncColumns {
  /// Column is `text`; the getter cannot be, because `text()` is the builder.
  TextColumn get body => text().named('text')();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}

/// One row per local calendar day, keyed `yyyy-MM-dd`.
class DailyLogs extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get top3TaskIds => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  DateTimeColumn get bedLoggedAt => dateTime().nullable()();
  DateTimeColumn get wakeLoggedAt => dateTime().nullable()();
  DateTimeColumn get eatDoneAt => dateTime().nullable()();
  BoolColumn get routineDone => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// A "just start" session. While [endedAt] is null the session is live:
/// running until `startedAt + durationMinutes`, then waiting for the owner
/// to stop or keep going. Once ended, [durationMinutes] is the time
/// actually spent and [completed] says whether the planned time was reached.
class FocusSessions extends Table with UuidKey, SyncColumns {
  TextColumn get taskId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// v4.
  DateTimeColumn get endedAt => dateTime().nullable()();
}

/// What a reminder is for. The owner id's meaning depends on the kind:
/// a task id for [deadline], a weekday for the routine kinds, and so on.
enum ReminderKind { wake, eat, leave, deadline, windDown, focusEnd, test }

/// Every notification handed to Android, so reminders can be cancelled by
/// owner and rebuilt from data (CLAUDE.md rule 2). [notificationId] is the
/// int Android needs; it is unique across all rows, deleted ones included.
class ScheduledNotifications extends Table with UuidKey, SyncColumns {
  IntColumn get notificationId => integer().unique()();
  TextColumn get kind => textEnum<ReminderKind>()();
  TextColumn get ownerId => text()();
  DateTimeColumn get fireAt => dateTime()();
  TextColumn get title => text()();
  TextColumn get body => text()();
}

/// "Not today" for one reminder owner on one local day (`yyyy-MM-dd`).
class ReminderMutes extends Table with UuidKey, SyncColumns {
  TextColumn get kind => textEnum<ReminderKind>()();
  TextColumn get ownerId => text()();
  TextColumn get date => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {kind, ownerId, date},
  ];
}

/// JSON list of strings in a text column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
