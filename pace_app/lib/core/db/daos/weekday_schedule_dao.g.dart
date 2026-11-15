// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekday_schedule_dao.dart';

// ignore_for_file: type=lint
mixin _$WeekdayScheduleDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeekdaySchedulesTable get weekdaySchedules =>
      attachedDatabase.weekdaySchedules;
  WeekdayScheduleDaoManager get managers => WeekdayScheduleDaoManager(this);
}

class WeekdayScheduleDaoManager {
  final _$WeekdayScheduleDaoMixin _db;
  WeekdayScheduleDaoManager(this._db);
  $$WeekdaySchedulesTableTableManager get weekdaySchedules =>
      $$WeekdaySchedulesTableTableManager(
        _db.attachedDatabase,
        _db.weekdaySchedules,
      );
}
