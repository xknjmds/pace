// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_dao.dart';

// ignore_for_file: type=lint
mixin _$InboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $InboxItemsTable get inboxItems => attachedDatabase.inboxItems;
  InboxDaoManager get managers => InboxDaoManager(this);
}

class InboxDaoManager {
  final _$InboxDaoMixin _db;
  InboxDaoManager(this._db);
  $$InboxItemsTableTableManager get inboxItems =>
      $$InboxItemsTableTableManager(_db.attachedDatabase, _db.inboxItems);
}
