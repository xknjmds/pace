/// How a routine step went, as the owner tells it. Never inferred.
///
/// Pure Dart (no Flutter or Drift) so domain code and tables share it.
enum CheckInOutcome {
  /// Done around the planned time.
  onTime,

  /// Done, a bit later than planned.
  later,

  /// Didn't happen today. Not a failure, just what the day was.
  didntHappen,
}
