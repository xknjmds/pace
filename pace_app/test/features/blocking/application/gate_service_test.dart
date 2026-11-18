import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/blocking/application/app_gate.dart';
import 'package:pace/features/blocking/application/gate_service.dart';
import 'package:pace/features/blocking/domain/lock_windows.dart';

import '../../../core/db/test_db.dart';

class FakeGate implements AppGate {
  final configs = <GateConfig>[];
  GateConfig get last => configs.last;

  @override
  Future<void> configure(GateConfig config) async => configs.add(config);
  @override
  Future<List<InstalledApp>> installedApps() async => const [];
  @override
  Future<void> openOverlaySettings() async {}
  @override
  Future<void> openUsageAccessSettings() async {}
  @override
  Future<GatePermissions> permissions() async =>
      const GatePermissions(usageAccess: true, overlay: true);
  @override
  Future<void> unlockFor(int minutes) async {}
  @override
  Future<DateTime?> unlockedUntil() async => null;
}

void main() {
  final start = DateTime(
    2026,
    11,
    16,
    6,
    40,
  ); // Monday, inside the morning lock
  late TestDb t;
  late FakeGate gate;
  late GateService service;

  setUp(() async {
    t = TestDb(start.toUtc());
    gate = FakeGate();
    service = GateService(db: t.db, gate: gate, now: () => t.now.toLocal());
    await t.db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 8 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await t.db.blockedAppsDao.add('com.example.video', 'Video');
  });
  tearDown(() => t.close());

  test('off by default sends "disabled"', () async {
    await service.sync();
    expect(gate.last.enabled, isFalse);
  });

  test('on: blocked apps and the morning window under way', () async {
    await service.setEnabled(true);
    expect(gate.last.enabled, isTrue);
    expect(gate.last.packages, ['com.example.video']);
    expect(activeWindow(gate.last.windows, start)?.reason, LockReason.morning);
  });

  test('finishing the routine opens the gate at once', () async {
    await service.setEnabled(true);
    await t.db.dailyLogsDao.setRoutineDone(start, true);
    await service.sync();
    expect(activeWindow(gate.last.windows, start), isNull);
  });

  test('turning the gate off removes all blocking', () async {
    await service.setEnabled(true);
    await service.setEnabled(false);
    expect(gate.last.enabled, isFalse);
    expect(gate.last.windows, isEmpty);
  });

  test('no apps chosen means nothing to block', () async {
    await t.db.blockedAppsDao.remove('com.example.video');
    await service.setEnabled(true);
    expect(gate.last.enabled, isFalse);
  });
}
