import 'package:flutter/material.dart';

import '../theme/pace_theme.dart';
import 'cairn_mark.dart';

/// Shown instead of the app on anything that is not Android (for example
/// when an editor launches it in Chrome or on the desktop). PACE's
/// database, reminders and widget are Android-only, so nothing else runs.
class UnsupportedPlatformApp extends StatelessWidget {
  const UnsupportedPlatformApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PACE',
    theme: PaceTheme.light(),
    darkTheme: PaceTheme.dark(),
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CairnMark(size: 72),
                    const SizedBox(height: 24),
                    Text(
                      'PACE runs on Android',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Its reminders and home-screen widget need an Android '
                      'phone or emulator. Connect one and run it there.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
