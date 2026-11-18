import 'package:flutter/material.dart';

/// One soft colour pair: a pastel fill and the deeper tone used for its
/// icon and text on top.
@immutable
class Pastel {
  const Pastel(this.fill, this.ink);

  final Color fill;
  final Color ink;

  static Pastel lerp(Pastel a, Pastel b, double t) =>
      Pastel(Color.lerp(a.fill, b.fill, t)!, Color.lerp(a.ink, b.ink, t)!);
}

/// What a block of the day is, so it gets its own soft colour.
enum PastelKind { morning, leave, deadline, focus, evening, calm }

/// Soft activity colours, Tiimo-style: brand tints (dawn, moss, sand) plus
/// two muted extras (sky for focus, dusk lilac for evening). Never red.
@immutable
class PacePastels extends ThemeExtension<PacePastels> {
  const PacePastels({
    required this.morning,
    required this.leave,
    required this.deadline,
    required this.focus,
    required this.evening,
    required this.calm,
  });

  /// Wake and eat: dawn.
  final Pastel morning;

  /// Leaving and class: moss.
  final Pastel leave;

  /// Things due: warm sand.
  final Pastel deadline;

  /// Focus and the timer: soft sky.
  final Pastel focus;

  /// Wind-down and bed: dusk lilac.
  final Pastel evening;

  /// Neutral, low-energy, notes: sage.
  final Pastel calm;

  Pastel forKind(PastelKind kind) => switch (kind) {
    PastelKind.morning => morning,
    PastelKind.leave => leave,
    PastelKind.deadline => deadline,
    PastelKind.focus => focus,
    PastelKind.evening => evening,
    PastelKind.calm => calm,
  };

  static const light = PacePastels(
    morning: Pastel(Color(0xFFF7E8CC), Color(0xFF8A5E14)),
    leave: Pastel(Color(0xFFDCEAE3), Color(0xFF2B5A4E)),
    deadline: Pastel(Color(0xFFF0E4D2), Color(0xFF7A5634)),
    focus: Pastel(Color(0xFFDCE8EF), Color(0xFF365D73)),
    evening: Pastel(Color(0xFFE7E2F0), Color(0xFF55497A)),
    calm: Pastel(Color(0xFFE4EAE3), Color(0xFF465C52)),
  );

  static const dark = PacePastels(
    morning: Pastel(Color(0xFF3E3320), Color(0xFFF0CF96)),
    leave: Pastel(Color(0xFF2A4139), Color(0xFFAFD3C4)),
    deadline: Pastel(Color(0xFF3B3226), Color(0xFFE6C9A6)),
    focus: Pastel(Color(0xFF263A45), Color(0xFFA9CBE0)),
    evening: Pastel(Color(0xFF35304A), Color(0xFFCDC3EC)),
    calm: Pastel(Color(0xFF2C3833), Color(0xFFC0D3C9)),
  );

  static PacePastels of(BuildContext context) =>
      Theme.of(context).extension<PacePastels>() ?? light;

  @override
  PacePastels copyWith({
    Pastel? morning,
    Pastel? leave,
    Pastel? deadline,
    Pastel? focus,
    Pastel? evening,
    Pastel? calm,
  }) => PacePastels(
    morning: morning ?? this.morning,
    leave: leave ?? this.leave,
    deadline: deadline ?? this.deadline,
    focus: focus ?? this.focus,
    evening: evening ?? this.evening,
    calm: calm ?? this.calm,
  );

  @override
  PacePastels lerp(PacePastels? other, double t) {
    if (other == null) return this;
    return PacePastels(
      morning: Pastel.lerp(morning, other.morning, t),
      leave: Pastel.lerp(leave, other.leave, t),
      deadline: Pastel.lerp(deadline, other.deadline, t),
      focus: Pastel.lerp(focus, other.focus, t),
      evening: Pastel.lerp(evening, other.evening, t),
      calm: Pastel.lerp(calm, other.calm, t),
    );
  }
}
