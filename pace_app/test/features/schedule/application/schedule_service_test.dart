import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/schedule/application/schedule_service.dart';
import 'package:pace/features/schedule/domain/schedule_parser.dart';

import '../../../core/db/test_db.dart';
import '../../../core/home_widget/fake_home_widget_bridge.dart';

void main() {
  late TestDb t;
  late FakeHomeWidgetBridge widget;
  late ScheduleService service;
  var resyncs = 0;

  setUp(() {
    t = TestDb();
    widget = FakeHomeWidgetBridge();
    resyncs = 0;
    service = ScheduleService(
      db: t.db,
      widget: widget,
      resyncReminders: () async => resyncs++,
      now: () => t.now,
    );
  });
  tearDown(() => t.close());

  const math = CandidateBlock(
    weekday: 1,
    subject: 'Math',
    start: 480,
    end: 540,
  );
  const art = CandidateBlock(weekday: 1, subject: 'Art', start: 600, end: 660);
  const noTime = CandidateBlock(weekday: 2, subject: 'PE');

  test(
    'confirming saves complete blocks only and updates the widget',
    () async {
      await service.confirmImport([
        math,
        art,
        noTime,
      ], useAsFirstClass: const {});
      expect((await t.db.classBlocksDao.getAll()).map((b) => b.subject), [
        'Math',
        'Art',
      ]);
      final json = jsonDecode(widget.schedules.last) as Map<String, dynamic>;
      expect((json['classes'] as Map)['1'], hasLength(2));
      expect(resyncs, 0); // no first-class change, no re-plan
    },
  );

  test(
    'chosen weekdays take the earliest block as first class and re-plan',
    () async {
      await t.db.weekdayScheduleDao.upsert(
        weekday: 1,
        firstClassMinutes: 7 * 60,
        commuteMinutes: 40,
        prepMinutes: 20,
      );
      await service.confirmImport([art, math], useAsFirstClass: const {1});
      final row = await t.db.weekdayScheduleDao.getFor(1);
      expect(row!.firstClassMinutes, 480);
      expect(row.commuteMinutes, 40); // the rest of the day is kept
      expect(resyncs, 1);
    },
  );

  test('weekdays not chosen keep their first class time', () async {
    await t.db.weekdayScheduleDao.upsert(
      weekday: 1,
      firstClassMinutes: 7 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await service.confirmImport([math], useAsFirstClass: const {});
    expect(
      (await t.db.weekdayScheduleDao.getFor(1))!.firstClassMinutes,
      7 * 60,
    );
  });
}
