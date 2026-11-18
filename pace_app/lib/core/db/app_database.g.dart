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
  static const VerificationMeta _captureShortcutEnabledMeta =
      const VerificationMeta('captureShortcutEnabled');
  @override
  late final GeneratedColumn<bool> captureShortcutEnabled =
      GeneratedColumn<bool>(
        'capture_shortcut_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("capture_shortcut_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
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
    captureShortcutEnabled,
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
    if (data.containsKey('capture_shortcut_enabled')) {
      context.handle(
        _captureShortcutEnabledMeta,
        captureShortcutEnabled.isAcceptableOrUnknown(
          data['capture_shortcut_enabled']!,
          _captureShortcutEnabledMeta,
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
      captureShortcutEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}capture_shortcut_enabled'],
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

  /// v3: keep a "capture a thought" notification with an inline reply field.
  final bool captureShortcutEnabled;
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
    required this.captureShortcutEnabled,
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
    map['capture_shortcut_enabled'] = Variable<bool>(captureShortcutEnabled);
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
      captureShortcutEnabled: Value(captureShortcutEnabled),
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
      captureShortcutEnabled: serializer.fromJson<bool>(
        json['captureShortcutEnabled'],
      ),
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
      'captureShortcutEnabled': serializer.toJson<bool>(captureShortcutEnabled),
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
    bool? captureShortcutEnabled,
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
    captureShortcutEnabled:
        captureShortcutEnabled ?? this.captureShortcutEnabled,
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
      captureShortcutEnabled: data.captureShortcutEnabled.present
          ? data.captureShortcutEnabled.value
          : this.captureShortcutEnabled,
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
          ..write('lowEnergyEnabled: $lowEnergyEnabled, ')
          ..write('captureShortcutEnabled: $captureShortcutEnabled')
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
    captureShortcutEnabled,
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
          other.lowEnergyEnabled == this.lowEnergyEnabled &&
          other.captureShortcutEnabled == this.captureShortcutEnabled);
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
  final Value<bool> captureShortcutEnabled;
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
    this.captureShortcutEnabled = const Value.absent(),
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
    this.captureShortcutEnabled = const Value.absent(),
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
    Expression<bool>? captureShortcutEnabled,
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
      if (captureShortcutEnabled != null)
        'capture_shortcut_enabled': captureShortcutEnabled,
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
    Value<bool>? captureShortcutEnabled,
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
      captureShortcutEnabled:
          captureShortcutEnabled ?? this.captureShortcutEnabled,
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
    if (captureShortcutEnabled.present) {
      map['capture_shortcut_enabled'] = Variable<bool>(
        captureShortcutEnabled.value,
      );
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
          ..write('lowEnergyEnabled: $lowEnergyEnabled, ')
          ..write('captureShortcutEnabled: $captureShortcutEnabled')
          ..write(')'))
        .toString();
  }
}

class $WeekdaySchedulesTable extends WeekdaySchedules
    with TableInfo<$WeekdaySchedulesTable, WeekdaySchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekdaySchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
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
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstClassMinutesMeta = const VerificationMeta(
    'firstClassMinutes',
  );
  @override
  late final GeneratedColumn<int> firstClassMinutes = GeneratedColumn<int>(
    'first_class_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commuteMinutesMeta = const VerificationMeta(
    'commuteMinutes',
  );
  @override
  late final GeneratedColumn<int> commuteMinutes = GeneratedColumn<int>(
    'commute_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _prepMinutesMeta = const VerificationMeta(
    'prepMinutes',
  );
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
    'prep_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    weekday,
    firstClassMinutes,
    commuteMinutes,
    prepMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekday_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeekdaySchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('first_class_minutes')) {
      context.handle(
        _firstClassMinutesMeta,
        firstClassMinutes.isAcceptableOrUnknown(
          data['first_class_minutes']!,
          _firstClassMinutesMeta,
        ),
      );
    }
    if (data.containsKey('commute_minutes')) {
      context.handle(
        _commuteMinutesMeta,
        commuteMinutes.isAcceptableOrUnknown(
          data['commute_minutes']!,
          _commuteMinutesMeta,
        ),
      );
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
        _prepMinutesMeta,
        prepMinutes.isAcceptableOrUnknown(
          data['prep_minutes']!,
          _prepMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {weekday},
  ];
  @override
  WeekdaySchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeekdaySchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      firstClassMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_class_minutes'],
      ),
      commuteMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}commute_minutes'],
      )!,
      prepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_minutes'],
      )!,
    );
  }

  @override
  $WeekdaySchedulesTable createAlias(String alias) {
    return $WeekdaySchedulesTable(attachedDatabase, alias);
  }
}

class WeekdaySchedule extends DataClass implements Insertable<WeekdaySchedule> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int weekday;
  final int? firstClassMinutes;
  final int commuteMinutes;
  final int prepMinutes;
  const WeekdaySchedule({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.weekday,
    this.firstClassMinutes,
    required this.commuteMinutes,
    required this.prepMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['weekday'] = Variable<int>(weekday);
    if (!nullToAbsent || firstClassMinutes != null) {
      map['first_class_minutes'] = Variable<int>(firstClassMinutes);
    }
    map['commute_minutes'] = Variable<int>(commuteMinutes);
    map['prep_minutes'] = Variable<int>(prepMinutes);
    return map;
  }

  WeekdaySchedulesCompanion toCompanion(bool nullToAbsent) {
    return WeekdaySchedulesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      weekday: Value(weekday),
      firstClassMinutes: firstClassMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(firstClassMinutes),
      commuteMinutes: Value(commuteMinutes),
      prepMinutes: Value(prepMinutes),
    );
  }

  factory WeekdaySchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeekdaySchedule(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      weekday: serializer.fromJson<int>(json['weekday']),
      firstClassMinutes: serializer.fromJson<int?>(json['firstClassMinutes']),
      commuteMinutes: serializer.fromJson<int>(json['commuteMinutes']),
      prepMinutes: serializer.fromJson<int>(json['prepMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'weekday': serializer.toJson<int>(weekday),
      'firstClassMinutes': serializer.toJson<int?>(firstClassMinutes),
      'commuteMinutes': serializer.toJson<int>(commuteMinutes),
      'prepMinutes': serializer.toJson<int>(prepMinutes),
    };
  }

  WeekdaySchedule copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? weekday,
    Value<int?> firstClassMinutes = const Value.absent(),
    int? commuteMinutes,
    int? prepMinutes,
  }) => WeekdaySchedule(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    weekday: weekday ?? this.weekday,
    firstClassMinutes: firstClassMinutes.present
        ? firstClassMinutes.value
        : this.firstClassMinutes,
    commuteMinutes: commuteMinutes ?? this.commuteMinutes,
    prepMinutes: prepMinutes ?? this.prepMinutes,
  );
  WeekdaySchedule copyWithCompanion(WeekdaySchedulesCompanion data) {
    return WeekdaySchedule(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      firstClassMinutes: data.firstClassMinutes.present
          ? data.firstClassMinutes.value
          : this.firstClassMinutes,
      commuteMinutes: data.commuteMinutes.present
          ? data.commuteMinutes.value
          : this.commuteMinutes,
      prepMinutes: data.prepMinutes.present
          ? data.prepMinutes.value
          : this.prepMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeekdaySchedule(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('weekday: $weekday, ')
          ..write('firstClassMinutes: $firstClassMinutes, ')
          ..write('commuteMinutes: $commuteMinutes, ')
          ..write('prepMinutes: $prepMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    weekday,
    firstClassMinutes,
    commuteMinutes,
    prepMinutes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeekdaySchedule &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.weekday == this.weekday &&
          other.firstClassMinutes == this.firstClassMinutes &&
          other.commuteMinutes == this.commuteMinutes &&
          other.prepMinutes == this.prepMinutes);
}

class WeekdaySchedulesCompanion extends UpdateCompanion<WeekdaySchedule> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> weekday;
  final Value<int?> firstClassMinutes;
  final Value<int> commuteMinutes;
  final Value<int> prepMinutes;
  final Value<int> rowid;
  const WeekdaySchedulesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.weekday = const Value.absent(),
    this.firstClassMinutes = const Value.absent(),
    this.commuteMinutes = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeekdaySchedulesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required int weekday,
    this.firstClassMinutes = const Value.absent(),
    this.commuteMinutes = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       weekday = Value(weekday);
  static Insertable<WeekdaySchedule> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? weekday,
    Expression<int>? firstClassMinutes,
    Expression<int>? commuteMinutes,
    Expression<int>? prepMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (weekday != null) 'weekday': weekday,
      if (firstClassMinutes != null) 'first_class_minutes': firstClassMinutes,
      if (commuteMinutes != null) 'commute_minutes': commuteMinutes,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeekdaySchedulesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? weekday,
    Value<int?>? firstClassMinutes,
    Value<int>? commuteMinutes,
    Value<int>? prepMinutes,
    Value<int>? rowid,
  }) {
    return WeekdaySchedulesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      weekday: weekday ?? this.weekday,
      firstClassMinutes: firstClassMinutes ?? this.firstClassMinutes,
      commuteMinutes: commuteMinutes ?? this.commuteMinutes,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (firstClassMinutes.present) {
      map['first_class_minutes'] = Variable<int>(firstClassMinutes.value);
    }
    if (commuteMinutes.present) {
      map['commute_minutes'] = Variable<int>(commuteMinutes.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeekdaySchedulesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('weekday: $weekday, ')
          ..write('firstClassMinutes: $firstClassMinutes, ')
          ..write('commuteMinutes: $commuteMinutes, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<TaskSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('manual'),
      ).withConverter<TaskSource>($TasksTable.$convertersource);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    title,
    subject,
    dueAt,
    status,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      source: $TasksTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
  static JsonTypeConverter2<TaskSource, String, String> $convertersource =
      const EnumNameConverter<TaskSource>(TaskSource.values);
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String title;
  final String? subject;
  final DateTime dueAt;
  final TaskStatus status;
  final TaskSource source;
  final DateTime createdAt;
  const Task({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.title,
    this.subject,
    required this.dueAt,
    required this.status,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['due_at'] = Variable<DateTime>(dueAt);
    {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status),
      );
    }
    {
      map['source'] = Variable<String>(
        $TasksTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      dueAt: Value(dueAt),
      status: Value(status),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String?>(json['subject']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      source: $TasksTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String?>(subject),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'status': serializer.toJson<String>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'source': serializer.toJson<String>(
        $TasksTable.$convertersource.toJson(source),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? title,
    Value<String?> subject = const Value.absent(),
    DateTime? dueAt,
    TaskStatus? status,
    TaskSource? source,
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    title: title ?? this.title,
    subject: subject.present ? subject.value : this.subject,
    dueAt: dueAt ?? this.dueAt,
    status: status ?? this.status,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    title,
    subject,
    dueAt,
    status,
    source,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.dueAt == this.dueAt &&
          other.status == this.status &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> title;
  final Value<String?> subject;
  final Value<DateTime> dueAt;
  final Value<TaskStatus> status;
  final Value<TaskSource> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String title,
    this.subject = const Value.absent(),
    required DateTime dueAt,
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       title = Value(title),
       dueAt = Value(dueAt),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<DateTime>? dueAt,
    Expression<String>? status,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (dueAt != null) 'due_at': dueAt,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? title,
    Value<String?>? subject,
    Value<DateTime>? dueAt,
    Value<TaskStatus>? status,
    Value<TaskSource>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $TasksTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InboxItemsTable extends InboxItems
    with TableInfo<$InboxItemsTable, InboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
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
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedMeta = const VerificationMeta(
    'processed',
  );
  @override
  late final GeneratedColumn<bool> processed = GeneratedColumn<bool>(
    'processed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("processed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    body,
    createdAt,
    processed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('processed')) {
      context.handle(
        _processedMeta,
        processed.isAcceptableOrUnknown(data['processed']!, _processedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      processed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}processed'],
      )!,
    );
  }

  @override
  $InboxItemsTable createAlias(String alias) {
    return $InboxItemsTable(attachedDatabase, alias);
  }
}

class InboxItem extends DataClass implements Insertable<InboxItem> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Column is `text`; the getter cannot be, because `text()` is the builder.
  final String body;
  final DateTime createdAt;
  final bool processed;
  const InboxItem({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.body,
    required this.createdAt,
    required this.processed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['text'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['processed'] = Variable<bool>(processed);
    return map;
  }

  InboxItemsCompanion toCompanion(bool nullToAbsent) {
    return InboxItemsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      body: Value(body),
      createdAt: Value(createdAt),
      processed: Value(processed),
    );
  }

  factory InboxItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxItem(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      processed: serializer.fromJson<bool>(json['processed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'processed': serializer.toJson<bool>(processed),
    };
  }

  InboxItem copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? body,
    DateTime? createdAt,
    bool? processed,
  }) => InboxItem(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    processed: processed ?? this.processed,
  );
  InboxItem copyWithCompanion(InboxItemsCompanion data) {
    return InboxItem(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      processed: data.processed.present ? data.processed.value : this.processed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxItem(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('processed: $processed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, body, createdAt, processed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxItem &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.processed == this.processed);
}

class InboxItemsCompanion extends UpdateCompanion<InboxItem> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<bool> processed;
  final Value<int> rowid;
  const InboxItemsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.processed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InboxItemsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String body,
    required DateTime createdAt,
    this.processed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<InboxItem> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<bool>? processed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (body != null) 'text': body,
      if (createdAt != null) 'created_at': createdAt,
      if (processed != null) 'processed': processed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InboxItemsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<bool>? processed,
    Value<int>? rowid,
  }) {
    return InboxItemsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      processed: processed ?? this.processed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (processed.present) {
      map['processed'] = Variable<bool>(processed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboxItemsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('processed: $processed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyLogsTable extends DailyLogs
    with TableInfo<$DailyLogsTable, DailyLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  top3TaskIds = GeneratedColumn<String>(
    'top3_task_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($DailyLogsTable.$convertertop3TaskIds);
  static const VerificationMeta _bedLoggedAtMeta = const VerificationMeta(
    'bedLoggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> bedLoggedAt = GeneratedColumn<DateTime>(
    'bed_logged_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wakeLoggedAtMeta = const VerificationMeta(
    'wakeLoggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> wakeLoggedAt = GeneratedColumn<DateTime>(
    'wake_logged_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eatDoneAtMeta = const VerificationMeta(
    'eatDoneAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatDoneAt = GeneratedColumn<DateTime>(
    'eat_done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routineDoneMeta = const VerificationMeta(
    'routineDone',
  );
  @override
  late final GeneratedColumn<bool> routineDone = GeneratedColumn<bool>(
    'routine_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("routine_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    date,
    top3TaskIds,
    bedLoggedAt,
    wakeLoggedAt,
    eatDoneAt,
    routineDone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyLog> instance, {
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
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bed_logged_at')) {
      context.handle(
        _bedLoggedAtMeta,
        bedLoggedAt.isAcceptableOrUnknown(
          data['bed_logged_at']!,
          _bedLoggedAtMeta,
        ),
      );
    }
    if (data.containsKey('wake_logged_at')) {
      context.handle(
        _wakeLoggedAtMeta,
        wakeLoggedAt.isAcceptableOrUnknown(
          data['wake_logged_at']!,
          _wakeLoggedAtMeta,
        ),
      );
    }
    if (data.containsKey('eat_done_at')) {
      context.handle(
        _eatDoneAtMeta,
        eatDoneAt.isAcceptableOrUnknown(data['eat_done_at']!, _eatDoneAtMeta),
      );
    }
    if (data.containsKey('routine_done')) {
      context.handle(
        _routineDoneMeta,
        routineDone.isAcceptableOrUnknown(
          data['routine_done']!,
          _routineDoneMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyLog(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      top3TaskIds: $DailyLogsTable.$convertertop3TaskIds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}top3_task_ids'],
        )!,
      ),
      bedLoggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bed_logged_at'],
      ),
      wakeLoggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}wake_logged_at'],
      ),
      eatDoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eat_done_at'],
      ),
      routineDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}routine_done'],
      )!,
    );
  }

  @override
  $DailyLogsTable createAlias(String alias) {
    return $DailyLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertertop3TaskIds =
      const StringListConverter();
}

class DailyLog extends DataClass implements Insertable<DailyLog> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String date;
  final List<String> top3TaskIds;
  final DateTime? bedLoggedAt;
  final DateTime? wakeLoggedAt;
  final DateTime? eatDoneAt;
  final bool routineDone;
  const DailyLog({
    required this.updatedAt,
    this.deletedAt,
    required this.date,
    required this.top3TaskIds,
    this.bedLoggedAt,
    this.wakeLoggedAt,
    this.eatDoneAt,
    required this.routineDone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['date'] = Variable<String>(date);
    {
      map['top3_task_ids'] = Variable<String>(
        $DailyLogsTable.$convertertop3TaskIds.toSql(top3TaskIds),
      );
    }
    if (!nullToAbsent || bedLoggedAt != null) {
      map['bed_logged_at'] = Variable<DateTime>(bedLoggedAt);
    }
    if (!nullToAbsent || wakeLoggedAt != null) {
      map['wake_logged_at'] = Variable<DateTime>(wakeLoggedAt);
    }
    if (!nullToAbsent || eatDoneAt != null) {
      map['eat_done_at'] = Variable<DateTime>(eatDoneAt);
    }
    map['routine_done'] = Variable<bool>(routineDone);
    return map;
  }

  DailyLogsCompanion toCompanion(bool nullToAbsent) {
    return DailyLogsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      date: Value(date),
      top3TaskIds: Value(top3TaskIds),
      bedLoggedAt: bedLoggedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(bedLoggedAt),
      wakeLoggedAt: wakeLoggedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(wakeLoggedAt),
      eatDoneAt: eatDoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(eatDoneAt),
      routineDone: Value(routineDone),
    );
  }

  factory DailyLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyLog(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      date: serializer.fromJson<String>(json['date']),
      top3TaskIds: serializer.fromJson<List<String>>(json['top3TaskIds']),
      bedLoggedAt: serializer.fromJson<DateTime?>(json['bedLoggedAt']),
      wakeLoggedAt: serializer.fromJson<DateTime?>(json['wakeLoggedAt']),
      eatDoneAt: serializer.fromJson<DateTime?>(json['eatDoneAt']),
      routineDone: serializer.fromJson<bool>(json['routineDone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'date': serializer.toJson<String>(date),
      'top3TaskIds': serializer.toJson<List<String>>(top3TaskIds),
      'bedLoggedAt': serializer.toJson<DateTime?>(bedLoggedAt),
      'wakeLoggedAt': serializer.toJson<DateTime?>(wakeLoggedAt),
      'eatDoneAt': serializer.toJson<DateTime?>(eatDoneAt),
      'routineDone': serializer.toJson<bool>(routineDone),
    };
  }

  DailyLog copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? date,
    List<String>? top3TaskIds,
    Value<DateTime?> bedLoggedAt = const Value.absent(),
    Value<DateTime?> wakeLoggedAt = const Value.absent(),
    Value<DateTime?> eatDoneAt = const Value.absent(),
    bool? routineDone,
  }) => DailyLog(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    date: date ?? this.date,
    top3TaskIds: top3TaskIds ?? this.top3TaskIds,
    bedLoggedAt: bedLoggedAt.present ? bedLoggedAt.value : this.bedLoggedAt,
    wakeLoggedAt: wakeLoggedAt.present ? wakeLoggedAt.value : this.wakeLoggedAt,
    eatDoneAt: eatDoneAt.present ? eatDoneAt.value : this.eatDoneAt,
    routineDone: routineDone ?? this.routineDone,
  );
  DailyLog copyWithCompanion(DailyLogsCompanion data) {
    return DailyLog(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      date: data.date.present ? data.date.value : this.date,
      top3TaskIds: data.top3TaskIds.present
          ? data.top3TaskIds.value
          : this.top3TaskIds,
      bedLoggedAt: data.bedLoggedAt.present
          ? data.bedLoggedAt.value
          : this.bedLoggedAt,
      wakeLoggedAt: data.wakeLoggedAt.present
          ? data.wakeLoggedAt.value
          : this.wakeLoggedAt,
      eatDoneAt: data.eatDoneAt.present ? data.eatDoneAt.value : this.eatDoneAt,
      routineDone: data.routineDone.present
          ? data.routineDone.value
          : this.routineDone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyLog(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('top3TaskIds: $top3TaskIds, ')
          ..write('bedLoggedAt: $bedLoggedAt, ')
          ..write('wakeLoggedAt: $wakeLoggedAt, ')
          ..write('eatDoneAt: $eatDoneAt, ')
          ..write('routineDone: $routineDone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    date,
    top3TaskIds,
    bedLoggedAt,
    wakeLoggedAt,
    eatDoneAt,
    routineDone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyLog &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.date == this.date &&
          other.top3TaskIds == this.top3TaskIds &&
          other.bedLoggedAt == this.bedLoggedAt &&
          other.wakeLoggedAt == this.wakeLoggedAt &&
          other.eatDoneAt == this.eatDoneAt &&
          other.routineDone == this.routineDone);
}

class DailyLogsCompanion extends UpdateCompanion<DailyLog> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> date;
  final Value<List<String>> top3TaskIds;
  final Value<DateTime?> bedLoggedAt;
  final Value<DateTime?> wakeLoggedAt;
  final Value<DateTime?> eatDoneAt;
  final Value<bool> routineDone;
  final Value<int> rowid;
  const DailyLogsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.date = const Value.absent(),
    this.top3TaskIds = const Value.absent(),
    this.bedLoggedAt = const Value.absent(),
    this.wakeLoggedAt = const Value.absent(),
    this.eatDoneAt = const Value.absent(),
    this.routineDone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyLogsCompanion.insert({
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String date,
    this.top3TaskIds = const Value.absent(),
    this.bedLoggedAt = const Value.absent(),
    this.wakeLoggedAt = const Value.absent(),
    this.eatDoneAt = const Value.absent(),
    this.routineDone = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       date = Value(date);
  static Insertable<DailyLog> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? date,
    Expression<String>? top3TaskIds,
    Expression<DateTime>? bedLoggedAt,
    Expression<DateTime>? wakeLoggedAt,
    Expression<DateTime>? eatDoneAt,
    Expression<bool>? routineDone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (date != null) 'date': date,
      if (top3TaskIds != null) 'top3_task_ids': top3TaskIds,
      if (bedLoggedAt != null) 'bed_logged_at': bedLoggedAt,
      if (wakeLoggedAt != null) 'wake_logged_at': wakeLoggedAt,
      if (eatDoneAt != null) 'eat_done_at': eatDoneAt,
      if (routineDone != null) 'routine_done': routineDone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyLogsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? date,
    Value<List<String>>? top3TaskIds,
    Value<DateTime?>? bedLoggedAt,
    Value<DateTime?>? wakeLoggedAt,
    Value<DateTime?>? eatDoneAt,
    Value<bool>? routineDone,
    Value<int>? rowid,
  }) {
    return DailyLogsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      date: date ?? this.date,
      top3TaskIds: top3TaskIds ?? this.top3TaskIds,
      bedLoggedAt: bedLoggedAt ?? this.bedLoggedAt,
      wakeLoggedAt: wakeLoggedAt ?? this.wakeLoggedAt,
      eatDoneAt: eatDoneAt ?? this.eatDoneAt,
      routineDone: routineDone ?? this.routineDone,
      rowid: rowid ?? this.rowid,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (top3TaskIds.present) {
      map['top3_task_ids'] = Variable<String>(
        $DailyLogsTable.$convertertop3TaskIds.toSql(top3TaskIds.value),
      );
    }
    if (bedLoggedAt.present) {
      map['bed_logged_at'] = Variable<DateTime>(bedLoggedAt.value);
    }
    if (wakeLoggedAt.present) {
      map['wake_logged_at'] = Variable<DateTime>(wakeLoggedAt.value);
    }
    if (eatDoneAt.present) {
      map['eat_done_at'] = Variable<DateTime>(eatDoneAt.value);
    }
    if (routineDone.present) {
      map['routine_done'] = Variable<bool>(routineDone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('top3TaskIds: $top3TaskIds, ')
          ..write('bedLoggedAt: $bedLoggedAt, ')
          ..write('wakeLoggedAt: $wakeLoggedAt, ')
          ..write('eatDoneAt: $eatDoneAt, ')
          ..write('routineDone: $routineDone, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
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
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    taskId,
    startedAt,
    durationMinutes,
    completed,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSession extends DataClass implements Insertable<FocusSession> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? taskId;
  final DateTime startedAt;
  final int durationMinutes;
  final bool completed;

  /// v4.
  final DateTime? endedAt;
  const FocusSession({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    this.taskId,
    required this.startedAt,
    required this.durationMinutes,
    required this.completed,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      startedAt: Value(startedAt),
      durationMinutes: Value(durationMinutes),
      completed: Value(completed),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory FocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSession(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      completed: serializer.fromJson<bool>(json['completed']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'taskId': serializer.toJson<String?>(taskId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'completed': serializer.toJson<bool>(completed),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  FocusSession copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    DateTime? startedAt,
    int? durationMinutes,
    bool? completed,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => FocusSession(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    taskId: taskId.present ? taskId.value : this.taskId,
    startedAt: startedAt ?? this.startedAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    completed: completed ?? this.completed,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  FocusSession copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSession(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      completed: data.completed.present ? data.completed.value : this.completed,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSession(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('completed: $completed, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    taskId,
    startedAt,
    durationMinutes,
    completed,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.taskId == this.taskId &&
          other.startedAt == this.startedAt &&
          other.durationMinutes == this.durationMinutes &&
          other.completed == this.completed &&
          other.endedAt == this.endedAt);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSession> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> taskId;
  final Value<DateTime> startedAt;
  final Value<int> durationMinutes;
  final Value<bool> completed;
  final Value<DateTime?> endedAt;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.completed = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.taskId = const Value.absent(),
    required DateTime startedAt,
    required int durationMinutes,
    this.completed = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       startedAt = Value(startedAt),
       durationMinutes = Value(durationMinutes);
  static Insertable<FocusSession> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? taskId,
    Expression<DateTime>? startedAt,
    Expression<int>? durationMinutes,
    Expression<bool>? completed,
    Expression<DateTime>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (taskId != null) 'task_id': taskId,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (completed != null) 'completed': completed,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? taskId,
    Value<DateTime>? startedAt,
    Value<int>? durationMinutes,
    Value<bool>? completed,
    Value<DateTime?>? endedAt,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
      endedAt: endedAt ?? this.endedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('completed: $completed, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduledNotificationsTable extends ScheduledNotifications
    with TableInfo<$ScheduledNotificationsTable, ScheduledNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
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
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderKind>(
        $ScheduledNotificationsTable.$converterkind,
      );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fireAtMeta = const VerificationMeta('fireAt');
  @override
  late final GeneratedColumn<DateTime> fireAt = GeneratedColumn<DateTime>(
    'fire_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    notificationId,
    kind,
    ownerId,
    fireAt,
    title,
    body,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduledNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('fire_at')) {
      context.handle(
        _fireAtMeta,
        fireAt.isAcceptableOrUnknown(data['fire_at']!, _fireAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fireAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      kind: $ScheduledNotificationsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      fireAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fire_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $ScheduledNotificationsTable createAlias(String alias) {
    return $ScheduledNotificationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderKind, String, String> $converterkind =
      const EnumNameConverter<ReminderKind>(ReminderKind.values);
}

class ScheduledNotification extends DataClass
    implements Insertable<ScheduledNotification> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int notificationId;
  final ReminderKind kind;
  final String ownerId;
  final DateTime fireAt;
  final String title;
  final String body;
  const ScheduledNotification({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.notificationId,
    required this.kind,
    required this.ownerId,
    required this.fireAt,
    required this.title,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['notification_id'] = Variable<int>(notificationId);
    {
      map['kind'] = Variable<String>(
        $ScheduledNotificationsTable.$converterkind.toSql(kind),
      );
    }
    map['owner_id'] = Variable<String>(ownerId);
    map['fire_at'] = Variable<DateTime>(fireAt);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    return map;
  }

  ScheduledNotificationsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledNotificationsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      notificationId: Value(notificationId),
      kind: Value(kind),
      ownerId: Value(ownerId),
      fireAt: Value(fireAt),
      title: Value(title),
      body: Value(body),
    );
  }

  factory ScheduledNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledNotification(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      kind: $ScheduledNotificationsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      fireAt: serializer.fromJson<DateTime>(json['fireAt']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'notificationId': serializer.toJson<int>(notificationId),
      'kind': serializer.toJson<String>(
        $ScheduledNotificationsTable.$converterkind.toJson(kind),
      ),
      'ownerId': serializer.toJson<String>(ownerId),
      'fireAt': serializer.toJson<DateTime>(fireAt),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  ScheduledNotification copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? notificationId,
    ReminderKind? kind,
    String? ownerId,
    DateTime? fireAt,
    String? title,
    String? body,
  }) => ScheduledNotification(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    notificationId: notificationId ?? this.notificationId,
    kind: kind ?? this.kind,
    ownerId: ownerId ?? this.ownerId,
    fireAt: fireAt ?? this.fireAt,
    title: title ?? this.title,
    body: body ?? this.body,
  );
  ScheduledNotification copyWithCompanion(
    ScheduledNotificationsCompanion data,
  ) {
    return ScheduledNotification(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      kind: data.kind.present ? data.kind.value : this.kind,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      fireAt: data.fireAt.present ? data.fireAt.value : this.fireAt,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotification(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('notificationId: $notificationId, ')
          ..write('kind: $kind, ')
          ..write('ownerId: $ownerId, ')
          ..write('fireAt: $fireAt, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    notificationId,
    kind,
    ownerId,
    fireAt,
    title,
    body,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledNotification &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.notificationId == this.notificationId &&
          other.kind == this.kind &&
          other.ownerId == this.ownerId &&
          other.fireAt == this.fireAt &&
          other.title == this.title &&
          other.body == this.body);
}

class ScheduledNotificationsCompanion
    extends UpdateCompanion<ScheduledNotification> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> notificationId;
  final Value<ReminderKind> kind;
  final Value<String> ownerId;
  final Value<DateTime> fireAt;
  final Value<String> title;
  final Value<String> body;
  final Value<int> rowid;
  const ScheduledNotificationsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.kind = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.fireAt = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduledNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required int notificationId,
    required ReminderKind kind,
    required String ownerId,
    required DateTime fireAt,
    required String title,
    required String body,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       notificationId = Value(notificationId),
       kind = Value(kind),
       ownerId = Value(ownerId),
       fireAt = Value(fireAt),
       title = Value(title),
       body = Value(body);
  static Insertable<ScheduledNotification> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? notificationId,
    Expression<String>? kind,
    Expression<String>? ownerId,
    Expression<DateTime>? fireAt,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (notificationId != null) 'notification_id': notificationId,
      if (kind != null) 'kind': kind,
      if (ownerId != null) 'owner_id': ownerId,
      if (fireAt != null) 'fire_at': fireAt,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduledNotificationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? notificationId,
    Value<ReminderKind>? kind,
    Value<String>? ownerId,
    Value<DateTime>? fireAt,
    Value<String>? title,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return ScheduledNotificationsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      notificationId: notificationId ?? this.notificationId,
      kind: kind ?? this.kind,
      ownerId: ownerId ?? this.ownerId,
      fireAt: fireAt ?? this.fireAt,
      title: title ?? this.title,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ScheduledNotificationsTable.$converterkind.toSql(kind.value),
      );
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (fireAt.present) {
      map['fire_at'] = Variable<DateTime>(fireAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('notificationId: $notificationId, ')
          ..write('kind: $kind, ')
          ..write('ownerId: $ownerId, ')
          ..write('fireAt: $fireAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderMutesTable extends ReminderMutes
    with TableInfo<$ReminderMutesTable, ReminderMute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderMutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
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
  @override
  late final GeneratedColumnWithTypeConverter<ReminderKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderKind>($ReminderMutesTable.$converterkind);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    kind,
    ownerId,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_mutes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderMute> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {kind, ownerId, date},
  ];
  @override
  ReminderMute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderMute(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      kind: $ReminderMutesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $ReminderMutesTable createAlias(String alias) {
    return $ReminderMutesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderKind, String, String> $converterkind =
      const EnumNameConverter<ReminderKind>(ReminderKind.values);
}

class ReminderMute extends DataClass implements Insertable<ReminderMute> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final ReminderKind kind;
  final String ownerId;
  final String date;
  const ReminderMute({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.kind,
    required this.ownerId,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['kind'] = Variable<String>(
        $ReminderMutesTable.$converterkind.toSql(kind),
      );
    }
    map['owner_id'] = Variable<String>(ownerId);
    map['date'] = Variable<String>(date);
    return map;
  }

  ReminderMutesCompanion toCompanion(bool nullToAbsent) {
    return ReminderMutesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      kind: Value(kind),
      ownerId: Value(ownerId),
      date: Value(date),
    );
  }

  factory ReminderMute.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderMute(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      kind: $ReminderMutesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'kind': serializer.toJson<String>(
        $ReminderMutesTable.$converterkind.toJson(kind),
      ),
      'ownerId': serializer.toJson<String>(ownerId),
      'date': serializer.toJson<String>(date),
    };
  }

  ReminderMute copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    ReminderKind? kind,
    String? ownerId,
    String? date,
  }) => ReminderMute(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    kind: kind ?? this.kind,
    ownerId: ownerId ?? this.ownerId,
    date: date ?? this.date,
  );
  ReminderMute copyWithCompanion(ReminderMutesCompanion data) {
    return ReminderMute(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderMute(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('kind: $kind, ')
          ..write('ownerId: $ownerId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, kind, ownerId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderMute &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.kind == this.kind &&
          other.ownerId == this.ownerId &&
          other.date == this.date);
}

class ReminderMutesCompanion extends UpdateCompanion<ReminderMute> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<ReminderKind> kind;
  final Value<String> ownerId;
  final Value<String> date;
  final Value<int> rowid;
  const ReminderMutesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderMutesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required ReminderKind kind,
    required String ownerId,
    required String date,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       kind = Value(kind),
       ownerId = Value(ownerId),
       date = Value(date);
  static Insertable<ReminderMute> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? kind,
    Expression<String>? ownerId,
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (kind != null) 'kind': kind,
      if (ownerId != null) 'owner_id': ownerId,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderMutesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<ReminderKind>? kind,
    Value<String>? ownerId,
    Value<String>? date,
    Value<int>? rowid,
  }) {
    return ReminderMutesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      kind: kind ?? this.kind,
      ownerId: ownerId ?? this.ownerId,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ReminderMutesTable.$converterkind.toSql(kind.value),
      );
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderMutesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('kind: $kind, ')
          ..write('ownerId: $ownerId, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $WeekdaySchedulesTable weekdaySchedules = $WeekdaySchedulesTable(
    this,
  );
  late final $TasksTable tasks = $TasksTable(this);
  late final $InboxItemsTable inboxItems = $InboxItemsTable(this);
  late final $DailyLogsTable dailyLogs = $DailyLogsTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $ScheduledNotificationsTable scheduledNotifications =
      $ScheduledNotificationsTable(this);
  late final $ReminderMutesTable reminderMutes = $ReminderMutesTable(this);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final WeekdayScheduleDao weekdayScheduleDao = WeekdayScheduleDao(
    this as AppDatabase,
  );
  late final TasksDao tasksDao = TasksDao(this as AppDatabase);
  late final InboxDao inboxDao = InboxDao(this as AppDatabase);
  late final DailyLogsDao dailyLogsDao = DailyLogsDao(this as AppDatabase);
  late final FocusSessionsDao focusSessionsDao = FocusSessionsDao(
    this as AppDatabase,
  );
  late final ScheduledNotificationsDao scheduledNotificationsDao =
      ScheduledNotificationsDao(this as AppDatabase);
  late final ReminderMutesDao reminderMutesDao = ReminderMutesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    weekdaySchedules,
    tasks,
    inboxItems,
    dailyLogs,
    focusSessions,
    scheduledNotifications,
    reminderMutes,
  ];
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
      Value<bool> captureShortcutEnabled,
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
      Value<bool> captureShortcutEnabled,
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

  ColumnFilters<bool> get captureShortcutEnabled => $composableBuilder(
    column: $table.captureShortcutEnabled,
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

  ColumnOrderings<bool> get captureShortcutEnabled => $composableBuilder(
    column: $table.captureShortcutEnabled,
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

  GeneratedColumn<bool> get captureShortcutEnabled => $composableBuilder(
    column: $table.captureShortcutEnabled,
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
                Value<bool> captureShortcutEnabled = const Value.absent(),
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
                captureShortcutEnabled: captureShortcutEnabled,
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
                Value<bool> captureShortcutEnabled = const Value.absent(),
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
                captureShortcutEnabled: captureShortcutEnabled,
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
typedef $$WeekdaySchedulesTableCreateCompanionBuilder =
    WeekdaySchedulesCompanion Function({
      Value<String> id,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required int weekday,
      Value<int?> firstClassMinutes,
      Value<int> commuteMinutes,
      Value<int> prepMinutes,
      Value<int> rowid,
    });
typedef $$WeekdaySchedulesTableUpdateCompanionBuilder =
    WeekdaySchedulesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> weekday,
      Value<int?> firstClassMinutes,
      Value<int> commuteMinutes,
      Value<int> prepMinutes,
      Value<int> rowid,
    });

class $$WeekdaySchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $WeekdaySchedulesTable> {
  $$WeekdaySchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstClassMinutes => $composableBuilder(
    column: $table.firstClassMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commuteMinutes => $composableBuilder(
    column: $table.commuteMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeekdaySchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeekdaySchedulesTable> {
  $$WeekdaySchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstClassMinutes => $composableBuilder(
    column: $table.firstClassMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commuteMinutes => $composableBuilder(
    column: $table.commuteMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeekdaySchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeekdaySchedulesTable> {
  $$WeekdaySchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get firstClassMinutes => $composableBuilder(
    column: $table.firstClassMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get commuteMinutes => $composableBuilder(
    column: $table.commuteMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => column,
  );
}

class $$WeekdaySchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeekdaySchedulesTable,
          WeekdaySchedule,
          $$WeekdaySchedulesTableFilterComposer,
          $$WeekdaySchedulesTableOrderingComposer,
          $$WeekdaySchedulesTableAnnotationComposer,
          $$WeekdaySchedulesTableCreateCompanionBuilder,
          $$WeekdaySchedulesTableUpdateCompanionBuilder,
          (
            WeekdaySchedule,
            BaseReferences<
              _$AppDatabase,
              $WeekdaySchedulesTable,
              WeekdaySchedule
            >,
          ),
          WeekdaySchedule,
          PrefetchHooks Function()
        > {
  $$WeekdaySchedulesTableTableManager(
    _$AppDatabase db,
    $WeekdaySchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekdaySchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekdaySchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekdaySchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int?> firstClassMinutes = const Value.absent(),
                Value<int> commuteMinutes = const Value.absent(),
                Value<int> prepMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekdaySchedulesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                weekday: weekday,
                firstClassMinutes: firstClassMinutes,
                commuteMinutes: commuteMinutes,
                prepMinutes: prepMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required int weekday,
                Value<int?> firstClassMinutes = const Value.absent(),
                Value<int> commuteMinutes = const Value.absent(),
                Value<int> prepMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekdaySchedulesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                weekday: weekday,
                firstClassMinutes: firstClassMinutes,
                commuteMinutes: commuteMinutes,
                prepMinutes: prepMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeekdaySchedulesTable, WeekdaySchedule>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WeekdaySchedulesTable,
                    WeekdaySchedule
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeekdaySchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeekdaySchedulesTable,
      WeekdaySchedule,
      $$WeekdaySchedulesTableFilterComposer,
      $$WeekdaySchedulesTableOrderingComposer,
      $$WeekdaySchedulesTableAnnotationComposer,
      $$WeekdaySchedulesTableCreateCompanionBuilder,
      $$WeekdaySchedulesTableUpdateCompanionBuilder,
      (
        WeekdaySchedule,
        BaseReferences<_$AppDatabase, $WeekdaySchedulesTable, WeekdaySchedule>,
      ),
      WeekdaySchedule,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String title,
      Value<String?> subject,
      required DateTime dueAt,
      Value<TaskStatus> status,
      Value<TaskSource> source,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> title,
      Value<String?> subject,
      Value<DateTime> dueAt,
      Value<TaskStatus> status,
      Value<TaskSource> source,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TaskSource, TaskSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<TaskSource> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                subject: subject,
                dueAt: dueAt,
                status: status,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String title,
                Value<String?> subject = const Value.absent(),
                required DateTime dueAt,
                Value<TaskStatus> status = const Value.absent(),
                Value<TaskSource> source = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                subject: subject,
                dueAt: dueAt,
                status: status,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  BaseReferences<_$AppDatabase, $TasksTable, Task>(
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$InboxItemsTableCreateCompanionBuilder =
    InboxItemsCompanion Function({
      Value<String> id,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String body,
      required DateTime createdAt,
      Value<bool> processed,
      Value<int> rowid,
    });
typedef $$InboxItemsTableUpdateCompanionBuilder =
    InboxItemsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<bool> processed,
      Value<int> rowid,
    });

class $$InboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get processed =>
      $composableBuilder(column: $table.processed, builder: (column) => column);
}

class $$InboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboxItemsTable,
          InboxItem,
          $$InboxItemsTableFilterComposer,
          $$InboxItemsTableOrderingComposer,
          $$InboxItemsTableAnnotationComposer,
          $$InboxItemsTableCreateCompanionBuilder,
          $$InboxItemsTableUpdateCompanionBuilder,
          (
            InboxItem,
            BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItem>,
          ),
          InboxItem,
          PrefetchHooks Function()
        > {
  $$InboxItemsTableTableManager(_$AppDatabase db, $InboxItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> processed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxItemsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                body: body,
                createdAt: createdAt,
                processed: processed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String body,
                required DateTime createdAt,
                Value<bool> processed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxItemsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                body: body,
                createdAt: createdAt,
                processed: processed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InboxItemsTable, InboxItem>(table),
                  BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItem>(
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

typedef $$InboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboxItemsTable,
      InboxItem,
      $$InboxItemsTableFilterComposer,
      $$InboxItemsTableOrderingComposer,
      $$InboxItemsTableAnnotationComposer,
      $$InboxItemsTableCreateCompanionBuilder,
      $$InboxItemsTableUpdateCompanionBuilder,
      (InboxItem, BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItem>),
      InboxItem,
      PrefetchHooks Function()
    >;
typedef $$DailyLogsTableCreateCompanionBuilder =
    DailyLogsCompanion Function({
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String date,
      Value<List<String>> top3TaskIds,
      Value<DateTime?> bedLoggedAt,
      Value<DateTime?> wakeLoggedAt,
      Value<DateTime?> eatDoneAt,
      Value<bool> routineDone,
      Value<int> rowid,
    });
typedef $$DailyLogsTableUpdateCompanionBuilder =
    DailyLogsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> date,
      Value<List<String>> top3TaskIds,
      Value<DateTime?> bedLoggedAt,
      Value<DateTime?> wakeLoggedAt,
      Value<DateTime?> eatDoneAt,
      Value<bool> routineDone,
      Value<int> rowid,
    });

class $$DailyLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get top3TaskIds => $composableBuilder(
    column: $table.top3TaskIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get bedLoggedAt => $composableBuilder(
    column: $table.bedLoggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get wakeLoggedAt => $composableBuilder(
    column: $table.wakeLoggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eatDoneAt => $composableBuilder(
    column: $table.eatDoneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get routineDone => $composableBuilder(
    column: $table.routineDone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get top3TaskIds => $composableBuilder(
    column: $table.top3TaskIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get bedLoggedAt => $composableBuilder(
    column: $table.bedLoggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get wakeLoggedAt => $composableBuilder(
    column: $table.wakeLoggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatDoneAt => $composableBuilder(
    column: $table.eatDoneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get routineDone => $composableBuilder(
    column: $table.routineDone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableAnnotationComposer({
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

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get top3TaskIds =>
      $composableBuilder(
        column: $table.top3TaskIds,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get bedLoggedAt => $composableBuilder(
    column: $table.bedLoggedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get wakeLoggedAt => $composableBuilder(
    column: $table.wakeLoggedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get eatDoneAt =>
      $composableBuilder(column: $table.eatDoneAt, builder: (column) => column);

  GeneratedColumn<bool> get routineDone => $composableBuilder(
    column: $table.routineDone,
    builder: (column) => column,
  );
}

class $$DailyLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyLogsTable,
          DailyLog,
          $$DailyLogsTableFilterComposer,
          $$DailyLogsTableOrderingComposer,
          $$DailyLogsTableAnnotationComposer,
          $$DailyLogsTableCreateCompanionBuilder,
          $$DailyLogsTableUpdateCompanionBuilder,
          (DailyLog, BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLog>),
          DailyLog,
          PrefetchHooks Function()
        > {
  $$DailyLogsTableTableManager(_$AppDatabase db, $DailyLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<List<String>> top3TaskIds = const Value.absent(),
                Value<DateTime?> bedLoggedAt = const Value.absent(),
                Value<DateTime?> wakeLoggedAt = const Value.absent(),
                Value<DateTime?> eatDoneAt = const Value.absent(),
                Value<bool> routineDone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyLogsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                date: date,
                top3TaskIds: top3TaskIds,
                bedLoggedAt: bedLoggedAt,
                wakeLoggedAt: wakeLoggedAt,
                eatDoneAt: eatDoneAt,
                routineDone: routineDone,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String date,
                Value<List<String>> top3TaskIds = const Value.absent(),
                Value<DateTime?> bedLoggedAt = const Value.absent(),
                Value<DateTime?> wakeLoggedAt = const Value.absent(),
                Value<DateTime?> eatDoneAt = const Value.absent(),
                Value<bool> routineDone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyLogsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                date: date,
                top3TaskIds: top3TaskIds,
                bedLoggedAt: bedLoggedAt,
                wakeLoggedAt: wakeLoggedAt,
                eatDoneAt: eatDoneAt,
                routineDone: routineDone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyLogsTable, DailyLog>(table),
                  BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLog>(
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

typedef $$DailyLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyLogsTable,
      DailyLog,
      $$DailyLogsTableFilterComposer,
      $$DailyLogsTableOrderingComposer,
      $$DailyLogsTableAnnotationComposer,
      $$DailyLogsTableCreateCompanionBuilder,
      $$DailyLogsTableUpdateCompanionBuilder,
      (DailyLog, BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLog>),
      DailyLog,
      PrefetchHooks Function()
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> taskId,
      required DateTime startedAt,
      required int durationMinutes,
      Value<bool> completed,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> taskId,
      Value<DateTime> startedAt,
      Value<int> durationMinutes,
      Value<bool> completed,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSession,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (
            FocusSession,
            BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
          ),
          FocusSession,
          PrefetchHooks Function()
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                startedAt: startedAt,
                durationMinutes: durationMinutes,
                completed: completed,
                endedAt: endedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                required DateTime startedAt,
                required int durationMinutes,
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                taskId: taskId,
                startedAt: startedAt,
                durationMinutes: durationMinutes,
                completed: completed,
                endedAt: endedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusSessionsTable, FocusSession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FocusSessionsTable,
                    FocusSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSession,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (
        FocusSession,
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
      ),
      FocusSession,
      PrefetchHooks Function()
    >;
typedef $$ScheduledNotificationsTableCreateCompanionBuilder =
    ScheduledNotificationsCompanion Function({
      Value<String> id,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required int notificationId,
      required ReminderKind kind,
      required String ownerId,
      required DateTime fireAt,
      required String title,
      required String body,
      Value<int> rowid,
    });
typedef $$ScheduledNotificationsTableUpdateCompanionBuilder =
    ScheduledNotificationsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> notificationId,
      Value<ReminderKind> kind,
      Value<String> ownerId,
      Value<DateTime> fireAt,
      Value<String> title,
      Value<String> body,
      Value<int> rowid,
    });

class $$ScheduledNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderKind, ReminderKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduledNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduledNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReminderKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<DateTime> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$ScheduledNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduledNotificationsTable,
          ScheduledNotification,
          $$ScheduledNotificationsTableFilterComposer,
          $$ScheduledNotificationsTableOrderingComposer,
          $$ScheduledNotificationsTableAnnotationComposer,
          $$ScheduledNotificationsTableCreateCompanionBuilder,
          $$ScheduledNotificationsTableUpdateCompanionBuilder,
          (
            ScheduledNotification,
            BaseReferences<
              _$AppDatabase,
              $ScheduledNotificationsTable,
              ScheduledNotification
            >,
          ),
          ScheduledNotification,
          PrefetchHooks Function()
        > {
  $$ScheduledNotificationsTableTableManager(
    _$AppDatabase db,
    $ScheduledNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledNotificationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ScheduledNotificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ScheduledNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<ReminderKind> kind = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<DateTime> fireAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduledNotificationsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                notificationId: notificationId,
                kind: kind,
                ownerId: ownerId,
                fireAt: fireAt,
                title: title,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required int notificationId,
                required ReminderKind kind,
                required String ownerId,
                required DateTime fireAt,
                required String title,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => ScheduledNotificationsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                notificationId: notificationId,
                kind: kind,
                ownerId: ownerId,
                fireAt: fireAt,
                title: title,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ScheduledNotificationsTable,
                    ScheduledNotification
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScheduledNotificationsTable,
                    ScheduledNotification
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduledNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduledNotificationsTable,
      ScheduledNotification,
      $$ScheduledNotificationsTableFilterComposer,
      $$ScheduledNotificationsTableOrderingComposer,
      $$ScheduledNotificationsTableAnnotationComposer,
      $$ScheduledNotificationsTableCreateCompanionBuilder,
      $$ScheduledNotificationsTableUpdateCompanionBuilder,
      (
        ScheduledNotification,
        BaseReferences<
          _$AppDatabase,
          $ScheduledNotificationsTable,
          ScheduledNotification
        >,
      ),
      ScheduledNotification,
      PrefetchHooks Function()
    >;
typedef $$ReminderMutesTableCreateCompanionBuilder =
    ReminderMutesCompanion Function({
      Value<String> id,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required ReminderKind kind,
      required String ownerId,
      required String date,
      Value<int> rowid,
    });
typedef $$ReminderMutesTableUpdateCompanionBuilder =
    ReminderMutesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<ReminderKind> kind,
      Value<String> ownerId,
      Value<String> date,
      Value<int> rowid,
    });

class $$ReminderMutesTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderMutesTable> {
  $$ReminderMutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderKind, ReminderKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderMutesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderMutesTable> {
  $$ReminderMutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderMutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderMutesTable> {
  $$ReminderMutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$ReminderMutesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderMutesTable,
          ReminderMute,
          $$ReminderMutesTableFilterComposer,
          $$ReminderMutesTableOrderingComposer,
          $$ReminderMutesTableAnnotationComposer,
          $$ReminderMutesTableCreateCompanionBuilder,
          $$ReminderMutesTableUpdateCompanionBuilder,
          (
            ReminderMute,
            BaseReferences<_$AppDatabase, $ReminderMutesTable, ReminderMute>,
          ),
          ReminderMute,
          PrefetchHooks Function()
        > {
  $$ReminderMutesTableTableManager(_$AppDatabase db, $ReminderMutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderMutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderMutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderMutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<ReminderKind> kind = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderMutesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                kind: kind,
                ownerId: ownerId,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required ReminderKind kind,
                required String ownerId,
                required String date,
                Value<int> rowid = const Value.absent(),
              }) => ReminderMutesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                kind: kind,
                ownerId: ownerId,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderMutesTable, ReminderMute>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReminderMutesTable,
                    ReminderMute
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderMutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderMutesTable,
      ReminderMute,
      $$ReminderMutesTableFilterComposer,
      $$ReminderMutesTableOrderingComposer,
      $$ReminderMutesTableAnnotationComposer,
      $$ReminderMutesTableCreateCompanionBuilder,
      $$ReminderMutesTableUpdateCompanionBuilder,
      (
        ReminderMute,
        BaseReferences<_$AppDatabase, $ReminderMutesTable, ReminderMute>,
      ),
      ReminderMute,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$WeekdaySchedulesTableTableManager get weekdaySchedules =>
      $$WeekdaySchedulesTableTableManager(_db, _db.weekdaySchedules);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$InboxItemsTableTableManager get inboxItems =>
      $$InboxItemsTableTableManager(_db, _db.inboxItems);
  $$DailyLogsTableTableManager get dailyLogs =>
      $$DailyLogsTableTableManager(_db, _db.dailyLogs);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$ScheduledNotificationsTableTableManager get scheduledNotifications =>
      $$ScheduledNotificationsTableTableManager(
        _db,
        _db.scheduledNotifications,
      );
  $$ReminderMutesTableTableManager get reminderMutes =>
      $$ReminderMutesTableTableManager(_db, _db.reminderMutes);
}
