import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What went wrong while starting up. Startup never stops at a failing
/// step: the app always opens, and Today says calmly what did not start.
class StartupReport {
  final List<String> problems = [];

  bool get ok => problems.isEmpty;

  /// Runs [step]; on failure records [name] and carries on.
  Future<void> guard(String name, Future<void> Function() step) async {
    try {
      await step();
    } catch (e, st) {
      problems.add(name);
      debugPrint('PACE startup step "$name" failed: $e\n$st');
    }
  }
}

/// Overridden in `main` with the report filled during startup.
final startupReportProvider = Provider<StartupReport>((_) => StartupReport());
