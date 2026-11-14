import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// A source of "now". Every piece of code that needs the current time reads
/// it through [clockProvider] so tests can freeze it.
typedef Clock = DateTime Function();

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
