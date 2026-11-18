import 'home_widget_bridge.dart';

/// Web and desktop have no home-screen widget.
class NoopHomeWidgetBridge implements HomeWidgetBridge {
  const NoopHomeWidgetBridge();

  @override
  Future<void> publishInboxCount(int count) async {}

  @override
  Future<void> publishSchedule(String json) async {}
}
