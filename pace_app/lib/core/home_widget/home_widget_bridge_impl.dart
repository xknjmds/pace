import 'package:home_widget/home_widget.dart';

import 'home_widget_bridge.dart';

class HomeWidgetBridgeImpl implements HomeWidgetBridge {
  const HomeWidgetBridgeImpl();

  @override
  Future<void> publishInboxCount(int count) async {
    await HomeWidget.saveWidgetData<int>(HomeWidgetKeys.inboxCount, count);
    await HomeWidget.updateWidget(androidName: HomeWidgetKeys.androidProvider);
  }

  @override
  Future<void> publishSchedule(String json) async {
    await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.schedule, json);
    await HomeWidget.updateWidget(androidName: HomeWidgetKeys.scheduleProvider);
  }
}
