import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/check_in/check_in_rules.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/check_in_sheet.dart';
import '../../blocking/application/gate_providers.dart';
import '../../routine/application/routine_providers.dart';
import '../../routine/domain/routine_reminder_planner.dart';
import '../domain/today_model.dart';

const stepKinds = {
  RoutineStep.wake: ReminderKind.wake,
  RoutineStep.eat: ReminderKind.eat,
  RoutineStep.leave: ReminderKind.leave,
  RoutineStep.windDown: ReminderKind.windDown,
};

/// Steps the owner said didn't happen today, from the day's check-ins.
Set<RoutineStep> skippedSteps(Map<ReminderKind, CheckIn> checkIns) => {
  for (final e in stepKinds.entries)
    if (checkIns[e.value]?.outcome == CheckInOutcome.didntHappen) e.key,
};

/// The step as Today shows it, for its planned time and state.
RoutineStepItem? stepItem(RoutineStatus? status, RoutineStep step) {
  final steps = switch (status) {
    StepsRemaining(:final steps) => steps,
    RunningLate(:final steps) => steps,
    RoutineAllDone(:final steps) => steps,
    NoClassToday(:final wake?) => [wake],
    _ => const <RoutineStepItem>[],
  };
  for (final s in steps) {
    if (s.step == step) return s;
  }
  return null;
}

/// Opens the check-in sheet for a routine step and applies the answer.
///
/// [checkIn] is today's existing check-in for the step; [loggedAt] the time
/// in `daily_logs` (for steps logged before check-ins existed).
Future<void> checkInStep(
  BuildContext context,
  WidgetRef ref, {
  required RoutineStep step,
  required RoutineStepItem? item,
  required DateTime now,
  required int graceMinutes,
  CheckIn? checkIn,
  DateTime? loggedAt,
}) async {
  final kind = stepKinds[step]!;
  final CheckInInitial? initial = checkIn != null
      ? (
          outcome: checkIn.outcome,
          at: checkIn.actualAt?.toLocal(),
          reason: checkIn.reason,
        )
      : item?.done == true
      ? (outcome: CheckInOutcome.onTime, at: loggedAt?.toLocal(), reason: null)
      : null;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await showCheckInSheet(
    context,
    title: item?.label ?? 'Check in',
    subject: CheckInSubject.routine,
    now: now,
    planned: item?.at,
    graceMinutes: graceMinutes,
    initial: initial,
    lowEnergy: ref.read(lowEnergyProvider),
  );
  if (result == null) return;
  final routine = ref.read(routineRemindersProvider);
  switch (result) {
    case CheckInCleared():
      await routine.clearCheckIn(kind, now.weekday);
      _say(messenger, 'Cleared. Check in whenever you like.');
    case CheckInSaved(:final outcome, :final at, :final reason):
      await routine.checkIn(kind, now.weekday, outcome, at: at, reason: reason);
      final local = at?.toLocal();
      _say(
        messenger,
        checkInNote(
          outcome,
          local == null ? null : LocalTime.of(local.hour, local.minute),
        ),
      );
  }
  await _syncGate(ref);
}

/// A settled (or reopened) morning can change the app gate's lock. The
/// gate is a nicety here: if it cannot be reached, the check-in still
/// stands.
Future<void> _syncGate(WidgetRef ref) async {
  try {
    await ref.read(gateServiceProvider).sync();
  } catch (e) {
    debugPrint('gate sync after check-in failed: $e');
  }
}

void _say(ScaffoldMessengerState? messenger, String message) => messenger
  ?..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));
