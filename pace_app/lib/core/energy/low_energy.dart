import '../db/app_database.dart';

/// Pure: whether [lightDayDate] (`yyyy-MM-dd`) is today.
bool isLightDay(String? lightDayDate, DateTime now) =>
    lightDayDate != null && lightDayDate == dateKey(now);

/// Pure: low-energy mode as every screen and planner should see it: the
/// switch in Settings, or a one-day light day.
bool effectiveLowEnergy({
  required bool enabled,
  required String? lightDayDate,
  required DateTime now,
}) => enabled || isLightDay(lightDayDate, now);

extension SettingLowEnergy on Setting {
  /// Low-energy mode in force at [now], light day included.
  bool lowEnergyAt(DateTime now) => effectiveLowEnergy(
    enabled: lowEnergyEnabled,
    lightDayDate: lightDayDate,
    now: now,
  );
}
