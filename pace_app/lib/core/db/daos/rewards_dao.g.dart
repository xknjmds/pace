// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards_dao.dart';

// ignore_for_file: type=lint
mixin _$RewardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RewardsTable get rewards => attachedDatabase.rewards;
  RewardsDaoManager get managers => RewardsDaoManager(this);
}

class RewardsDaoManager {
  final _$RewardsDaoMixin _db;
  RewardsDaoManager(this._db);
  $$RewardsTableTableManager get rewards =>
      $$RewardsTableTableManager(_db.attachedDatabase, _db.rewards);
}
