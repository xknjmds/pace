import 'package:flutter/material.dart';

import 'core/theme/pace_theme.dart';
import 'routes.dart';

class PaceApp extends StatelessWidget {
  const PaceApp({super.key, this.initialRoute = Routes.today});

  /// Where the app opens; the home-screen widget can ask for the Inbox.
  final String initialRoute;

  /// Lets startup code navigate (widget taps while the app is running).
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PACE',
      navigatorKey: navigatorKey,
      theme: PaceTheme.light(),
      darkTheme: PaceTheme.dark(),
      initialRoute: initialRoute,
      routes: Routes.table,
      debugShowCheckedModeBanner: false,
    );
  }
}
