import 'package:equatable/equatable.dart';

/// Base class for all timer states.
abstract class TimerState extends Equatable {
  final int seconds;

  const TimerState(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

/// The timer is actively running.
class TimerRunning extends TimerState {
  const TimerRunning(super.seconds);

  @override
  String toString() => 'TimerRunning(seconds: $seconds)';
}

/// The timer is stopped (no longer accepting ticks).
class TimerStopped extends TimerState {
  const TimerStopped(super.seconds);

  @override
  String toString() => 'TimerStopped(seconds: $seconds)';
}
