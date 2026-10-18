import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'timer_event.dart';
import 'timer_state.dart';

export 'timer_event.dart';
export 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  StreamSubscription<int>? _tickSubscription;

  TimerBloc() : super(const TimerRunning(0)) {
    on<TimerStarted>(_onStarted);
    on<TimerTicked>(_onTicked);
    on<TimerStopRequested>(_onStopped);
    on<TimerReset>(_onReset);
  }

  void _onStarted(TimerStarted event, Emitter<TimerState> emit) {
    _tickSubscription?.cancel();
    emit(const TimerRunning(0));
    _tickSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => tick + 1,
    ).listen((seconds) {
      add(TimerTicked(seconds));
    });
  }

  void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
    // Ignore ticks when the timer is stopped.
    if (state is TimerStopped) return;
    emit(TimerRunning(event.seconds));
  }

  void _onStopped(TimerStopRequested event, Emitter<TimerState> emit) {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    emit(TimerStopped(state.seconds));
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    emit(const TimerRunning(0));
  }

  @override
  Future<void> close() {
    _tickSubscription?.cancel();
    return super.close();
  }
}
