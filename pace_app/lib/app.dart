import 'package:flutter/material.dart';

import 'core/theme/pace_theme.dart';
import 'routes.dart';

class PaceApp extends StatelessWidget {
  const PaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PACE',
      theme: PaceTheme.light(),
      darkTheme: PaceTheme.dark(),
      initialRoute: Routes.today,
      routes: Routes.table,
      debugShowCheckedModeBanner: false,
    );
  }
}
