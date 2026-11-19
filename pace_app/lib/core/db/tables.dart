import 'dart:convert';

import 'package:drift/drift.dart';

import '../check_in/check_in_outcome.dart';
import 'uuid.dart';

export '../check_in/check_in_outcome.dart';
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

  /// v6: show the daily verse on Today and in the wake-up reminder.
  BoolColumn get verseEnabled => boolean().withDefault(const Constant(true))();

  /// v6: ISO 4217 code shown next to amounts (empty: plain numbers).
  TextColumn get currencyCode => text().withDefault(const Constant(''))();

  /// v6: app blocking gate. [gateEnabled] is the master switch; the two
  /// windows can be turned off on their own. [unlockMinutes] is how long
  /// an emergency unlock lasts.
  BoolColumn get gateEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get morningLockEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get windDownLockEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get unlockMinutes => integer().withDefault(const Constant(10))();

  /// v6: when calendar events were last fetched; null when never.
  DateTimeColumn get calendarSyncedAt => dateTime().nullable()();

  /// v8: when the first-run setup was finished or skipped; null shows it.
  DateTimeColumn get onboardedAt => dateTime().nullable()();

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

/// v7 adds [letGo]: closed without submitting ("couldn't submit"). Neutral,
/// never shown as a failure.
enum TaskStatus { pending, submitted, letGo }

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

  /// v6: when it was marked submitted, for the weekly counts. From v7 the
  /// owner can pick it (submitted late), and it is also set on [TaskStatus.letGo].
  DateTimeColumn get submittedAt => dateTime().nullable()();

  /// v7: optional short note from the check-in sheet ("printer broke").
  TextColumn get submitNote => text().nullable()();
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

/// v7: how a routine step went on a day, from the check-in sheet. One live
/// row per [day] (`yyyy-MM-dd`; the night's date for wind-down) and [kind].
/// `daily_logs` still holds the times the rest of the app reads.
class CheckIns extends Table with UuidKey, SyncColumns {
  TextColumn get day => text()();
  TextColumn get kind => textEnum<ReminderKind>()();
  TextColumn get outcome => textEnum<CheckInOutcome>()();
  DateTimeColumn get actualAt => dateTime().nullable()();
  TextColumn get reason => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {day, kind},
  ];
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
enum ReminderKind {
  wake,
  eat,
  leave,
  deadline,
  windDown,
  focusEnd,
  test,

  /// v6: the movement habit; owner id is the habit id.
  habit,
}

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

enum BlockSource { manual, image }

/// v6: one class on one weekday. Times are minutes since midnight.
class ClassBlocks extends Table with UuidKey, SyncColumns {
  IntColumn get weekday => integer()();
  TextColumn get subject => text()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get room => text().nullable()();
  TextColumn get source =>
      textEnum<BlockSource>().withDefault(const Constant('manual'))();
}

/// The routine point a habit reminder hangs off.
enum HabitAnchor { wake, eat, leave, windDown }

/// v6: a small daily habit with a reminder [offsetMinutes] after (or,
/// negative, before) its [anchor] in that day's routine.
class Habits extends Table with UuidKey, SyncColumns {
  TextColumn get name => text()();
  TextColumn get anchor =>
      textEnum<HabitAnchor>().withDefault(const Constant('wake'))();
  IntColumn get offsetMinutes => integer().withDefault(const Constant(30))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// v6: a habit marked done on one local day (`yyyy-MM-dd`).
class HabitLogs extends Table with UuidKey, SyncColumns {
  TextColumn get habitId => text()();
  TextColumn get date => text()();
  BoolColumn get done => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {habitId, date},
  ];
}

/// v6: an Android app the gate holds back during lock windows.
class BlockedApps extends Table with UuidKey, SyncColumns {
  TextColumn get packageName => text().unique()();
  TextColumn get label => text().withDefault(const Constant(''))();
}

/// v6: a note. Separate from the quick-capture inbox.
class Notes extends Table with UuidKey, SyncColumns {
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}

/// v6: money spent. [amountMinor] is in minor units (cents).
class Expenses extends Table with UuidKey, SyncColumns {
  IntColumn get amountMinor => integer()();
  TextColumn get category => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get spentAt => dateTime()();
}

enum BudgetPeriod { weekly, monthly }

/// v6: a spending budget. Only the newest live row is used.
class Budgets extends Table with UuidKey, SyncColumns {
  TextColumn get period => textEnum<BudgetPeriod>()();
  IntColumn get amountMinor => integer()();
}

/// v6: Google Calendar events cached for offline display.
class CalendarEvents extends Table with UuidKey, SyncColumns {
  TextColumn get externalId => text().unique()();
  TextColumn get title => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime()();
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
