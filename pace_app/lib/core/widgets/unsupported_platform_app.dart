import 'package:flutter/material.dart';

import '../theme/pace_theme.dart';
import 'animated_cairn.dart';
import 'pace_wordmark.dart';

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
                    const AnimatedCairn(size: 80),
                    const SizedBox(height: 20),
                    const PaceWordmark(height: 22),
                    const SizedBox(height: 32),
                    Text(
                      'PACE does not run here yet',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'It runs on Android, in a web browser and on Windows, '
                      'macOS and Linux.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
