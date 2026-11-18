import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/settings_provider.dart';
import 'core/theme/pace_theme.dart';
import 'core/theme/pace_tokens.dart';
import 'routes.dart';

class PaceApp extends ConsumerWidget {
  const PaceApp({super.key, this.initialRoute = Routes.today});

  /// Where the app opens; the home-screen widget can ask for the Inbox.
  final String initialRoute;

  /// Lets startup code navigate (widget taps while the app is running).
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Low-energy mode also quiets decorative motion everywhere.
    final calm = ref.watch(lowEnergyProvider);
    return MaterialApp(
      title: 'PACE',
      navigatorKey: navigatorKey,
      theme: PaceTheme.light(),
      darkTheme: PaceTheme.dark(),
      initialRoute: initialRoute,
      routes: Routes.table,
      onGenerateInitialRoutes: Routes.initialStack,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          PaceMotionScope(calm: calm, child: child ?? const SizedBox.shrink()),
    );
  }
}
