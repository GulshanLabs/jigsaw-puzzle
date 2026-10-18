import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/bloc/audio_settings/audio_settings_cubit.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/audio_settings.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/services/audio_service.dart';
import 'package:jigsaw_puzzle_game/ui/screens/board_screen.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/puzzle_piece_widget.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mock BLoCs
// ---------------------------------------------------------------------------

class MockPuzzleBloc extends MockBloc<PuzzleEvent, PuzzleBlocState>
    implements PuzzleBloc {}

class MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

class MockAudioSettingsCubit extends MockCubit<AudioSettingsState>
    implements AudioSettingsCubit {}

class MockAudioService extends Mock implements AudioService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid 1×1 white PNG (67 bytes).
Uint8List _whitePng() {
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE,
    0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
    0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
    0xAE, 0x42, 0x60, 0x82,
  ]);
}

List<Piece> _makePieces(int n) {
  final bytes = _whitePng();
  return [
    for (var r = 0; r < n; r++)
      for (var c = 0; c < n; c++)
        Piece(id: PieceId(r, c), imageBytes: bytes),
  ];
}

PuzzleState _solvedState(int n) {
  final pieces = _makePieces(n);
  final placement = <PieceId, BoardPosition>{
    for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
  };
  return PuzzleState(gridSize: n, sourceAspectRatio: 1.0, pieces: pieces, placement: placement);
}

PuzzleState _stateWithMoves(int n, int moveCount) {
  final pieces = _makePieces(n);
  final placement = <PieceId, BoardPosition>{
    for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
  };
  return PuzzleState(
    gridSize: n,
    sourceAspectRatio: 1.0,
    pieces: pieces,
    placement: placement,
    moveCount: moveCount,
  );
}

int _testKey = 0;

Widget _buildTestWidget({
  required PuzzleBloc puzzleBloc,
  required TimerBloc timerBloc,
  AudioSettingsCubit? audioSettingsCubit,
  AudioService? audioService,
}) {
  _testKey++;
  final mockAudioCubit = audioSettingsCubit ?? _defaultAudioSettingsCubit();
  final mockAudioSvc = audioService ?? _defaultAudioService();
  return MaterialApp(
    key: ValueKey('test_$_testKey'),
    routes: {
      '/completion': (_) => const Scaffold(body: Text('Completion')),
    },
    home: RepositoryProvider<AudioService>.value(
      value: mockAudioSvc,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PuzzleBloc>.value(value: puzzleBloc),
          BlocProvider<TimerBloc>.value(value: timerBloc),
          BlocProvider<AudioSettingsCubit>.value(value: mockAudioCubit),
        ],
        child: const BoardScreen(),
      ),
    ),
  );
}

MockAudioSettingsCubit _defaultAudioSettingsCubit() {
  final cubit = MockAudioSettingsCubit();
  when(() => cubit.state).thenReturn(
    const AudioSettingsState(
      isLoaded: true,
      settings: AudioSettings(),
    ),
  );
  return cubit;
}

MockAudioService _defaultAudioService() {
  final svc = MockAudioService();
  when(() => svc.playTapSound()).thenAnswer((_) async {});
  when(() => svc.playSwapSound()).thenAnswer((_) async {});
  return svc;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(const PieceTapped(PieceId(0, 0)));
  });

  group('BoardScreen — piece count', () {
    for (final n in [2, 3, 4, 5, 6]) {
      testWidgets('renders $n×$n = ${n * n} pieces', (tester) async {
        final puzzleBloc = MockPuzzleBloc();
        final timerBloc = MockTimerBloc();
        whenListen(
          puzzleBloc,
          const Stream<PuzzleBlocState>.empty(),
          initialState: BoardActive(state: _solvedState(n)),
        );
        whenListen(
          timerBloc,
          const Stream<TimerState>.empty(),
          initialState: const TimerRunning(0),
        );

        await tester.pumpWidget(_buildTestWidget(
          puzzleBloc: puzzleBloc,
          timerBloc: timerBloc,
        ));

        expect(find.byType(PuzzlePieceWidget), findsNWidgets(n * n));
      });
    }
  });

  group('BoardScreen — piece selection highlight', () {
    testWidgets('selected piece shows highlight border', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: BoardActive(
          state: _solvedState(2),
          selectedPieceId: const PieceId(0, 0),
        ),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(0),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      final selectedWidget = tester
          .widgetList<PuzzlePieceWidget>(find.byType(PuzzlePieceWidget))
          .where((w) => w.piece.id == const PieceId(0, 0))
          .first;
      expect(selectedWidget.isSelected, isTrue);

      final otherWidgets = tester
          .widgetList<PuzzlePieceWidget>(find.byType(PuzzlePieceWidget))
          .where((w) => w.piece.id != const PieceId(0, 0));
      for (final w in otherWidgets) {
        expect(w.isSelected, isFalse);
      }
    });

    testWidgets('tapping a piece dispatches PieceTapped event',
        (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: BoardActive(state: _solvedState(2)),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(0),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      await tester.tap(find.byType(PuzzlePieceWidget).first);
      await tester.pump();

      verify(() => puzzleBloc.add(any(that: isA<PieceTapped>()))).called(1);
    });

    testWidgets('no piece selected — no highlight borders', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: BoardActive(state: _solvedState(2)),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(0),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      final allWidgets = tester.widgetList<PuzzlePieceWidget>(
        find.byType(PuzzlePieceWidget),
      );
      for (final w in allWidgets) {
        expect(w.isSelected, isFalse);
      }
    });
  });

  group('BoardScreen — stats header', () {
    testWidgets('displays move count', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: BoardActive(state: _stateWithMoves(2, 42)),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(0),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      expect(find.text('Moves: 42'), findsOneWidget);
    });

    testWidgets('displays timer value formatted as mm:ss', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      // 125 seconds = 02:05
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: BoardActive(state: _solvedState(2)),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(125),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      expect(find.text('Time: 02:05'), findsOneWidget);
    });

    testWidgets('displays zero timer as 00:00', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: BoardActive(state: _solvedState(2)),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(0),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      expect(find.text('Time: 00:00'), findsOneWidget);
    });
  });

  group('BoardScreen — navigation', () {
    testWidgets('hides board when PuzzleSolved is emitted', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final timerBloc = MockTimerBloc();
      final state = _solvedState(2);
      final solvedState = PuzzleSolved(
        state: state,
        moveCount: 10,
        elapsedSeconds: 60,
      );

      whenListen(
        puzzleBloc,
        Stream<PuzzleBlocState>.fromIterable([solvedState]),
        initialState: BoardActive(state: state),
      );
      whenListen(
        timerBloc,
        const Stream<TimerState>.empty(),
        initialState: const TimerRunning(60),
      );

      await tester.pumpWidget(_buildTestWidget(
        puzzleBloc: puzzleBloc,
        timerBloc: timerBloc,
      ));

      await tester.pumpAndSettle();

      // When PuzzleSolved is emitted the board grid should no longer render
      // pieces because the BlocBuilder in _PuzzleGrid guards on BoardActive.
      expect(find.byType(PuzzlePieceWidget), findsNothing);
    });
  });
}
