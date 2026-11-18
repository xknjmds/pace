import 'package:pace/core/home_widget/home_widget_bridge.dart';

class FakeHomeWidgetBridge implements HomeWidgetBridge {
  final counts = <int>[];

  int? get last => counts.isEmpty ? null : counts.last;

  @override
  Future<void> publishInboxCount(int count) async => counts.add(count);

  final schedules = <String>[];

  @override
  Future<void> publishSchedule(String json) async => schedules.add(json);
}
