// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_mutes_dao.dart';

// ignore_for_file: type=lint
mixin _$ReminderMutesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReminderMutesTable get reminderMutes => attachedDatabase.reminderMutes;
  ReminderMutesDaoManager get managers => ReminderMutesDaoManager(this);
}

class ReminderMutesDaoManager {
  final _$ReminderMutesDaoMixin _db;
  ReminderMutesDaoManager(this._db);
  $$ReminderMutesTableTableManager get reminderMutes =>
      $$ReminderMutesTableTableManager(_db.attachedDatabase, _db.reminderMutes);
}
