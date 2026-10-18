import 'package:equatable/equatable.dart';

/// Base class for all timer events.
abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

/// Starts the timer from 0.
class TimerStarted extends TimerEvent {
  const TimerStarted();
}

/// Internal event dispatched every second by the periodic stream.
class TimerTicked extends TimerEvent {
  final int seconds;

  const TimerTicked(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

/// Stops the timer (idempotent — subsequent ticks are ignored).
class TimerStopRequested extends TimerEvent {
  const TimerStopRequested();
}

/// Resets the timer to 0.
class TimerReset extends TimerEvent {
  const TimerReset();
}
