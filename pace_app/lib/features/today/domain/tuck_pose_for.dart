import '../../../core/mascot/tuck_pose.dart';
import '../../routine/domain/routine_reminder_planner.dart';
import 'today_model.dart';

/// Which pose Tuck takes on Today, from what the day looks like right now.
///
/// Low-energy mode always wins: Tuck rests too. Nothing here ever maps to
/// a sad or worried Tuck; running late just means walking.
TuckPose tuckPoseFor({
  required DateTime now,
  required RoutineStatus? status,
  required bool evening,
  required bool lowEnergy,
  required bool focusRunning,
}) {
  if (lowEnergy) return TuckPose.resting;
  if (evening || now.hour >= 22 || now.hour < 5) return TuckPose.evening;
  if (focusRunning) return TuckPose.focus;
  return switch (status) {
    RunningLate() => TuckPose.leaving,
    StepsRemaining(:final next) => switch (next.step) {
      RoutineStep.wake || RoutineStep.eat => TuckPose.morning,
      RoutineStep.leave => TuckPose.leaving,
      RoutineStep.windDown => TuckPose.evening,
    },
    RoutineAllDone() => TuckPose.proud,
    NoClassToday(:final wake) when wake != null && !wake.done =>
      TuckPose.morning,
    _ => TuckPose.idle,
  };
}
