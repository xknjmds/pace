/// Tuck the turtle, PACE's mascot. Plain Dart so pose choice can be tested
/// without Flutter. Tuck is never sad or disappointed: a missed thing gets
/// [idle] or [resting], nothing else.
enum TuckPose {
  /// Standing, small wave. The default.
  idle('default'),

  /// Stretching awake, a small sun.
  morning('morning'),

  /// Walking with a school backpack.
  leaving('leaving'),

  /// Reading, head down. The focus timer.
  focus('focus'),

  /// Legs tucked into the shell. Low-energy mode.
  resting('resting'),

  /// In a blanket under a crescent moon. Wind-down and check-in.
  evening('evening'),

  /// Holding a note. The inbox.
  note('note'),

  /// Quietly pleased. Something done.
  proud('proud');

  const TuckPose(this.file);

  /// Image name in `assets/mascot/tuck_<file>.png`.
  final String file;
}
