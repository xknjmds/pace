// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWakeMinutesMeta = const VerificationMeta(
    'targetWakeMinutes',
  );
  @override
  late final GeneratedColumn<int> targetWakeMinutes = GeneratedColumn<int>(
    'target_wake_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6 * 60 + 30),
  );
  static const VerificationMeta _sleepTargetMinutesMeta =
      const VerificationMeta('sleepTargetMinutes');
  @override
  late final GeneratedColumn<int> sleepTargetMinutes = GeneratedColumn<int>(
    'sleep_target_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8 * 60),
  );
  static const VerificationMeta _windDownLeadMinutesMeta =
      const VerificationMeta('windDownLeadMinutes');
  @override
  late final GeneratedColumn<int> windDownLeadMinutes = GeneratedColumn<int>(
    'wind_down_lead_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(45),
  );
  static const VerificationMeta _breakfastMinutesMeta = const VerificationMeta(
    'breakfastMinutes',
  );
  @override
  late final GeneratedColumn<int> breakfastMinutes = GeneratedColumn<int>(
    'breakfast_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _lateThresholdMinutesMeta =
      const VerificationMeta('lateThresholdMinutes');
  @override
  late final GeneratedColumn<int> lateThresholdMinutes = GeneratedColumn<int>(
    'late_threshold_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _lowEnergyEnabledMeta = const VerificationMeta(
    'lowEnergyEnabled',
  );
  @override
  late final GeneratedColumn<bool> lowEnergyEnabled = GeneratedColumn<bool>(
    'low_energy_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("low_energy_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    targetWakeMinutes,
    sleepTargetMinutes,
    windDownLeadMinutes,
    breakfastMinutes,
    lateThresholdMinutes,
    lowEnergyEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_wake_minutes')) {
      context.handle(
        _targetWakeMinutesMeta,
        targetWakeMinutes.isAcceptableOrUnknown(
          data['target_wake_minutes']!,
          _targetWakeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('sleep_target_minutes')) {
      context.handle(
        _sleepTargetMinutesMeta,
        sleepTargetMinutes.isAcceptableOrUnknown(
          data['sleep_target_minutes']!,
          _sleepTargetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('wind_down_lead_minutes')) {
      context.handle(
        _windDownLeadMinutesMeta,
        windDownLeadMinutes.isAcceptableOrUnknown(
          data['wind_down_lead_minutes']!,
          _windDownLeadMinutesMeta,
        ),
      );
    }
    if (data.containsKey('breakfast_minutes')) {
      context.handle(
        _breakfastMinutesMeta,
        breakfastMinutes.isAcceptableOrUnknown(
          data['breakfast_minutes']!,
          _breakfastMinutesMeta,
        ),
      );
    }
    if (data.containsKey('late_threshold_minutes')) {
      context.handle(
        _lateThresholdMinutesMeta,
        lateThresholdMinutes.isAcceptableOrUnknown(
          data['late_threshold_minutes']!,
          _lateThresholdMinutesMeta,
        ),
      );
    }
    if (data.containsKey('low_energy_enabled')) {
      context.handle(
        _lowEnergyEnabledMeta,
        lowEnergyEnabled.isAcceptableOrUnknown(
          data['low_energy_enabled']!,
          _lowEnergyEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetWakeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_wake_minutes'],
      )!,
      sleepTargetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_target_minutes'],
      )!,
      windDownLeadMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wind_down_lead_minutes'],
      )!,
      breakfastMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}breakfast_minutes'],
      )!,
      lateThresholdMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_threshold_minutes'],
      )!,
      lowEnergyEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}low_energy_enabled'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final int targetWakeMinutes;
  final int sleepTargetMinutes;
  final int windDownLeadMinutes;
  final int breakfastMinutes;
  final int lateThresholdMinutes;
  final bool lowEnergyEnabled;
  const Setting({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.targetWakeMinutes,
    required this.sleepTargetMinutes,
    required this.windDownLeadMinutes,
    required this.breakfastMinutes,
    required this.lateThresholdMinutes,
    required this.lowEnergyEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<int>(id);
    map['target_wake_minutes'] = Variable<int>(targetWakeMinutes);
    map['sleep_target_minutes'] = Variable<int>(sleepTargetMinutes);
    map['wind_down_lead_minutes'] = Variable<int>(windDownLeadMinutes);
    map['breakfast_minutes'] = Variable<int>(breakfastMinutes);
    map['late_threshold_minutes'] = Variable<int>(lateThresholdMinutes);
    map['low_energy_enabled'] = Variable<bool>(lowEnergyEnabled);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      targetWakeMinutes: Value(targetWakeMinutes),
      sleepTargetMinutes: Value(sleepTargetMinutes),
      windDownLeadMinutes: Value(windDownLeadMinutes),
      breakfastMinutes: Value(breakfastMinutes),
      lateThresholdMinutes: Value(lateThresholdMinutes),
      lowEnergyEnabled: Value(lowEnergyEnabled),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      targetWakeMinutes: serializer.fromJson<int>(json['targetWakeMinutes']),
      sleepTargetMinutes: serializer.fromJson<int>(json['sleepTargetMinutes']),
      windDownLeadMinutes: serializer.fromJson<int>(
        json['windDownLeadMinutes'],
      ),
      breakfastMinutes: serializer.fromJson<int>(json['breakfastMinutes']),
      lateThresholdMinutes: serializer.fromJson<int>(
        json['lateThresholdMinutes'],
      ),
      lowEnergyEnabled: serializer.fromJson<bool>(json['lowEnergyEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<int>(id),
      'targetWakeMinutes': serializer.toJson<int>(targetWakeMinutes),
      'sleepTargetMinutes': serializer.toJson<int>(sleepTargetMinutes),
      'windDownLeadMinutes': serializer.toJson<int>(windDownLeadMinutes),
      'breakfastMinutes': serializer.toJson<int>(breakfastMinutes),
      'lateThresholdMinutes': serializer.toJson<int>(lateThresholdMinutes),
      'lowEnergyEnabled': serializer.toJson<bool>(lowEnergyEnabled),
    };
  }

  Setting copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    int? targetWakeMinutes,
    int? sleepTargetMinutes,
    int? windDownLeadMinutes,
    int? breakfastMinutes,
    int? lateThresholdMinutes,
    bool? lowEnergyEnabled,
  }) => Setting(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    targetWakeMinutes: targetWakeMinutes ?? this.targetWakeMinutes,
    sleepTargetMinutes: sleepTargetMinutes ?? this.sleepTargetMinutes,
    windDownLeadMinutes: windDownLeadMinutes ?? this.windDownLeadMinutes,
    breakfastMinutes: breakfastMinutes ?? this.breakfastMinutes,
    lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
    lowEnergyEnabled: lowEnergyEnabled ?? this.lowEnergyEnabled,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      targetWakeMinutes: data.targetWakeMinutes.present
          ? data.targetWakeMinutes.value
          : this.targetWakeMinutes,
      sleepTargetMinutes: data.sleepTargetMinutes.present
          ? data.sleepTargetMinutes.value
          : this.sleepTargetMinutes,
      windDownLeadMinutes: data.windDownLeadMinutes.present
          ? data.windDownLeadMinutes.value
          : this.windDownLeadMinutes,
      breakfastMinutes: data.breakfastMinutes.present
          ? data.breakfastMinutes.value
          : this.breakfastMinutes,
      lateThresholdMinutes: data.lateThresholdMinutes.present
          ? data.lateThresholdMinutes.value
          : this.lateThresholdMinutes,
      lowEnergyEnabled: data.lowEnergyEnabled.present
          ? data.lowEnergyEnabled.value
          : this.lowEnergyEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('targetWakeMinutes: $targetWakeMinutes, ')
          ..write('sleepTargetMinutes: $sleepTargetMinutes, ')
          ..write('windDownLeadMinutes: $windDownLeadMinutes, ')
          ..write('breakfastMinutes: $breakfastMinutes, ')
          ..write('lateThresholdMinutes: $lateThresholdMinutes, ')
          ..write('lowEnergyEnabled: $lowEnergyEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    targetWakeMinutes,
    sleepTargetMinutes,
    windDownLeadMinutes,
    breakfastMinutes,
    lateThresholdMinutes,
    lowEnergyEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.targetWakeMinutes == this.targetWakeMinutes &&
          other.sleepTargetMinutes == this.sleepTargetMinutes &&
          other.windDownLeadMinutes == this.windDownLeadMinutes &&
          other.breakfastMinutes == this.breakfastMinutes &&
          other.lateThresholdMinutes == this.lateThresholdMinutes &&
          other.lowEnergyEnabled == this.lowEnergyEnabled);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<int> targetWakeMinutes;
  final Value<int> sleepTargetMinutes;
  final Value<int> windDownLeadMinutes;
  final Value<int> breakfastMinutes;
  final Value<int> lateThresholdMinutes;
  final Value<bool> lowEnergyEnabled;
  const SettingsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.targetWakeMinutes = const Value.absent(),
    this.sleepTargetMinutes = const Value.absent(),
    this.windDownLeadMinutes = const Value.absent(),
    this.breakfastMinutes = const Value.absent(),
    this.lateThresholdMinutes = const Value.absent(),
    this.lowEnergyEnabled = const Value.absent(),
  });
  SettingsCompanion.insert({
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.targetWakeMinutes = const Value.absent(),
    this.sleepTargetMinutes = const Value.absent(),
    this.windDownLeadMinutes = const Value.absent(),
    this.breakfastMinutes = const Value.absent(),
    this.lateThresholdMinutes = const Value.absent(),
    this.lowEnergyEnabled = const Value.absent(),
  }) : updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<int>? targetWakeMinutes,
    Expression<int>? sleepTargetMinutes,
    Expression<int>? windDownLeadMinutes,
    Expression<int>? breakfastMinutes,
    Expression<int>? lateThresholdMinutes,
    Expression<bool>? lowEnergyEnabled,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (targetWakeMinutes != null) 'target_wake_minutes': targetWakeMinutes,
      if (sleepTargetMinutes != null)
        'sleep_target_minutes': sleepTargetMinutes,
      if (windDownLeadMinutes != null)
        'wind_down_lead_minutes': windDownLeadMinutes,
      if (breakfastMinutes != null) 'breakfast_minutes': breakfastMinutes,
      if (lateThresholdMinutes != null)
        'late_threshold_minutes': lateThresholdMinutes,
      if (lowEnergyEnabled != null) 'low_energy_enabled': lowEnergyEnabled,
    });
  }

  SettingsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<int>? targetWakeMinutes,
    Value<int>? sleepTargetMinutes,
    Value<int>? windDownLeadMinutes,
    Value<int>? breakfastMinutes,
    Value<int>? lateThresholdMinutes,
    Value<bool>? lowEnergyEnabled,
  }) {
    return SettingsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      targetWakeMinutes: targetWakeMinutes ?? this.targetWakeMinutes,
      sleepTargetMinutes: sleepTargetMinutes ?? this.sleepTargetMinutes,
      windDownLeadMinutes: windDownLeadMinutes ?? this.windDownLeadMinutes,
      breakfastMinutes: breakfastMinutes ?? this.breakfastMinutes,
      lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
      lowEnergyEnabled: lowEnergyEnabled ?? this.lowEnergyEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetWakeMinutes.present) {
      map['target_wake_minutes'] = Variable<int>(targetWakeMinutes.value);
    }
    if (sleepTargetMinutes.present) {
      map['sleep_target_minutes'] = Variable<int>(sleepTargetMinutes.value);
    }
    if (windDownLeadMinutes.present) {
      map['wind_down_lead_minutes'] = Variable<int>(windDownLeadMinutes.value);
    }
    if (breakfastMinutes.present) {
      map['breakfast_minutes'] = Variable<int>(breakfastMinutes.value);
    }
    if (lateThresholdMinutes.present) {
      map['late_threshold_minutes'] = Variable<int>(lateThresholdMinutes.value);
    }
    if (lowEnergyEnabled.present) {
      map['low_energy_enabled'] = Variable<bool>(lowEnergyEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('targetWakeMinutes: $targetWakeMinutes, ')
          ..write('sleepTargetMinutes: $sleepTargetMinutes, ')
          ..write('windDownLeadMinutes: $windDownLeadMinutes, ')
          ..write('breakfastMinutes: $breakfastMinutes, ')
          ..write('lateThresholdMinutes: $lateThresholdMinutes, ')
          ..write('lowEnergyEnabled: $lowEnergyEnabled')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [settings];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<int> targetWakeMinutes,
      Value<int> sleepTargetMinutes,
      Value<int> windDownLeadMinutes,
      Value<int> breakfastMinutes,
      Value<int> lateThresholdMinutes,
      Value<bool> lowEnergyEnabled,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<int> targetWakeMinutes,
      Value<int> sleepTargetMinutes,
      Value<int> windDownLeadMinutes,
      Value<int> breakfastMinutes,
      Value<int> lateThresholdMinutes,
      Value<bool> lowEnergyEnabled,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetWakeMinutes => $composableBuilder(
    column: $table.targetWakeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepTargetMinutes => $composableBuilder(
    column: $table.sleepTargetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windDownLeadMinutes => $composableBuilder(
    column: $table.windDownLeadMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakfastMinutes => $composableBuilder(
    column: $table.breakfastMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateThresholdMinutes => $composableBuilder(
    column: $table.lateThresholdMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lowEnergyEnabled => $composableBuilder(
    column: $table.lowEnergyEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetWakeMinutes => $composableBuilder(
    column: $table.targetWakeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepTargetMinutes => $composableBuilder(
    column: $table.sleepTargetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windDownLeadMinutes => $composableBuilder(
    column: $table.windDownLeadMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakfastMinutes => $composableBuilder(
    column: $table.breakfastMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateThresholdMinutes => $composableBuilder(
    column: $table.lateThresholdMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lowEnergyEnabled => $composableBuilder(
    column: $table.lowEnergyEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get targetWakeMinutes => $composableBuilder(
    column: $table.targetWakeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepTargetMinutes => $composableBuilder(
    column: $table.sleepTargetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windDownLeadMinutes => $composableBuilder(
    column: $table.windDownLeadMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakfastMinutes => $composableBuilder(
    column: $table.breakfastMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateThresholdMinutes => $composableBuilder(
    column: $table.lateThresholdMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lowEnergyEnabled => $composableBuilder(
    column: $table.lowEnergyEnabled,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<int> targetWakeMinutes = const Value.absent(),
                Value<int> sleepTargetMinutes = const Value.absent(),
                Value<int> windDownLeadMinutes = const Value.absent(),
                Value<int> breakfastMinutes = const Value.absent(),
                Value<int> lateThresholdMinutes = const Value.absent(),
                Value<bool> lowEnergyEnabled = const Value.absent(),
              }) => SettingsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                targetWakeMinutes: targetWakeMinutes,
                sleepTargetMinutes: sleepTargetMinutes,
                windDownLeadMinutes: windDownLeadMinutes,
                breakfastMinutes: breakfastMinutes,
                lateThresholdMinutes: lateThresholdMinutes,
                lowEnergyEnabled: lowEnergyEnabled,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<int> targetWakeMinutes = const Value.absent(),
                Value<int> sleepTargetMinutes = const Value.absent(),
                Value<int> windDownLeadMinutes = const Value.absent(),
                Value<int> breakfastMinutes = const Value.absent(),
                Value<int> lateThresholdMinutes = const Value.absent(),
                Value<bool> lowEnergyEnabled = const Value.absent(),
              }) => SettingsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                targetWakeMinutes: targetWakeMinutes,
                sleepTargetMinutes: sleepTargetMinutes,
                windDownLeadMinutes: windDownLeadMinutes,
                breakfastMinutes: breakfastMinutes,
                lateThresholdMinutes: lateThresholdMinutes,
                lowEnergyEnabled: lowEnergyEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db.attachedDatabase, _db.settings);
}
