import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';

void main() {
  group('TimerBloc', () {
    late TimerBloc timerBloc;

    setUp(() {
      timerBloc = TimerBloc();
    });

    tearDown(() {
      timerBloc.close();
    });

    test('initial state is TimerRunning(0)', () {
      expect(timerBloc.state, const TimerRunning(0));
    });

    blocTest<TimerBloc, TimerState>(
      'emits TimerRunning(0) when TimerStarted is added',
      build: () => TimerBloc(),
      act: (bloc) => bloc.add(const TimerStarted()),
      expect: () => [const TimerRunning(0)],
    );

    blocTest<TimerBloc, TimerState>(
      'emits TimerRunning with incrementing seconds on TimerTicked',
      build: () => TimerBloc(),
      act: (bloc) {
        bloc.add(const TimerTicked(1));
        bloc.add(const TimerTicked(2));
        bloc.add(const TimerTicked(3));
      },
      expect: () => [
        const TimerRunning(1),
        const TimerRunning(2),
        const TimerRunning(3),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'emits TimerStopped with current seconds when stop is requested',
      build: () => TimerBloc(),
      seed: () => const TimerRunning(5),
      act: (bloc) => bloc.add(const TimerStopRequested()),
      expect: () => [const TimerStopped(5)],
    );

    blocTest<TimerBloc, TimerState>(
      'ignores TimerTicked events after TimerStopRequested',
      build: () => TimerBloc(),
      seed: () => const TimerRunning(5),
      act: (bloc) {
        bloc.add(const TimerStopRequested());
        bloc.add(const TimerTicked(6));
        bloc.add(const TimerTicked(7));
      },
      expect: () => [
        const TimerStopped(5),
        // No further states — ticks are ignored.
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'TimerStopRequested is idempotent — multiple stops keep same seconds',
      build: () => TimerBloc(),
      seed: () => const TimerRunning(10),
      act: (bloc) {
        bloc.add(const TimerStopRequested());
        bloc.add(const TimerStopRequested());
      },
      expect: () => [
        const TimerStopped(10),
        // Second stop re-emits same state (bloc_test deduplicates equal states).
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'TimerReset emits TimerRunning(0)',
      build: () => TimerBloc(),
      seed: () => const TimerRunning(15),
      act: (bloc) => bloc.add(const TimerReset()),
      expect: () => [const TimerRunning(0)],
    );

    blocTest<TimerBloc, TimerState>(
      'TimerReset after stop emits TimerRunning(0)',
      build: () => TimerBloc(),
      seed: () => const TimerStopped(20),
      act: (bloc) => bloc.add(const TimerReset()),
      expect: () => [const TimerRunning(0)],
    );

    blocTest<TimerBloc, TimerState>(
      'full lifecycle: start → tick → stop → ticks ignored → reset',
      build: () => TimerBloc(),
      act: (bloc) {
        bloc.add(const TimerStarted());
        bloc.add(const TimerTicked(1));
        bloc.add(const TimerTicked(2));
        bloc.add(const TimerStopRequested());
        bloc.add(const TimerTicked(3)); // should be ignored
        bloc.add(const TimerReset());
      },
      expect: () => [
        const TimerRunning(0),
        const TimerRunning(1),
        const TimerRunning(2),
        const TimerStopped(2),
        // TimerTicked(3) is ignored
        const TimerRunning(0),
      ],
    );
  });
}
