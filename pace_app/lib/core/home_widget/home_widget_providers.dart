import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_widget_bridge.dart';

/// Overridden in `main` with the real bridge and in tests with a fake.
final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>(
  (_) => throw UnimplementedError(
    'homeWidgetBridgeProvider must be overridden at the ProviderScope',
  ),
);
