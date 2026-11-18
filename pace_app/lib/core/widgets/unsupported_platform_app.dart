import 'package:flutter/material.dart';

import '../theme/pace_theme.dart';
import 'cairn_mark.dart';

/// Shown instead of the app on a platform PACE is not built for (iOS).
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
                      'PACE does not run here yet',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'It runs on Android, in a web browser and on Windows, '
                      'macOS and Linux.',
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
