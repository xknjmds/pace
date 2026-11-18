// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_apps_dao.dart';

// ignore_for_file: type=lint
mixin _$BlockedAppsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockedAppsTable get blockedApps => attachedDatabase.blockedApps;
  BlockedAppsDaoManager get managers => BlockedAppsDaoManager(this);
}

class BlockedAppsDaoManager {
  final _$BlockedAppsDaoMixin _db;
  BlockedAppsDaoManager(this._db);
  $$BlockedAppsTableTableManager get blockedApps =>
      $$BlockedAppsTableTableManager(_db.attachedDatabase, _db.blockedApps);
}
