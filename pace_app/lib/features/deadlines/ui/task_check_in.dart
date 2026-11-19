import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/check_in/check_in_rules.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/check_in_sheet.dart';
import '../application/deadline_providers.dart';

/// Opens the check-in sheet for [task] and applies the answer: submitted
/// (now or at a picked time), or let go. Returns whether anything changed,
/// so a filled check can unfill when the sheet is dismissed.
Future<bool> checkInTask(BuildContext context, WidgetRef ref, Task task) async {
  final now = ref.read(clockProvider)();
  final closed = task.status != TaskStatus.pending;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await showCheckInSheet(
    context,
    title: task.title,
    subject: CheckInSubject.deadline,
    now: now,
    dueAt: task.dueAt.toLocal(),
    lowEnergy: ref.read(lowEnergyProvider),
    initial: closed
        ? (
            outcome: task.status == TaskStatus.letGo
                ? CheckInOutcome.didntHappen
                : task.submittedAt != null &&
                      task.submittedAt!.isAfter(task.dueAt)
                ? CheckInOutcome.later
                : CheckInOutcome.onTime,
            at: task.submittedAt?.toLocal(),
            reason: task.submitNote,
          )
        : null,
  );
  if (result == null) return false;
  final service = ref.read(deadlineRemindersProvider);
  switch (result) {
    case CheckInCleared():
      await service.markPending(task.id);
      _say(messenger, 'Back on the list.');
    case CheckInSaved(:final outcome, :final at, :final reason):
      if (outcome == CheckInOutcome.didntHappen) {
        await service.letGo(task.id, note: reason);
      } else {
        await service.submit(task.id, at: at, note: reason);
      }
      final local = at?.toLocal();
      _say(
        messenger,
        checkInNote(
          outcome,
          local == null ? null : LocalTime.of(local.hour, local.minute),
        ),
      );
  }
  return true;
}

void _say(ScaffoldMessengerState? messenger, String message) => messenger
  ?..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));
