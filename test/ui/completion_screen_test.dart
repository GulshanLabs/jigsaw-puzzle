import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/ui/screens/completion_screen.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mock BLoCs
// ---------------------------------------------------------------------------

class MockPuzzleBloc extends MockBloc<PuzzleEvent, PuzzleBlocState>
    implements PuzzleBloc {}

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

PuzzleState _solvedState(int n, {int moveCount = 0}) {
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

Widget _buildTestWidget({required PuzzleBloc puzzleBloc}) {
  _testKey++;
  return MaterialApp(
    key: ValueKey('completion_test_$_testKey'),
    routes: {
      '/board': (_) => const Scaffold(body: Text('Board')),
      '/home': (_) => const Scaffold(body: Text('Home')),
    },
    home: BlocProvider<PuzzleBloc>.value(
      value: puzzleBloc,
      child: const CompletionScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(const PlayAgainRequested());
    registerFallbackValue(const NewPuzzleRequested());
  });

  group('CompletionScreen — display', () {
    testWidgets('displays reconstructed image as grid of piece images',
        (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2, moveCount: 15);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 15,
          elapsedSeconds: 90,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      // 2×2 grid = 4 Image.memory widgets for the reconstructed image
      expect(find.byType(Image), findsNWidgets(4));
    });

    testWidgets('displays move count', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2, moveCount: 42);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 42,
          elapsedSeconds: 0,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
    });

    testWidgets('displays elapsed time formatted as mm:ss', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      // 125 seconds = 02:05
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 10,
          elapsedSeconds: 125,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      expect(find.text('02:05'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
    });

    testWidgets('displays both Play Again and New Puzzle buttons',
        (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('New Puzzle'), findsOneWidget);
    });
  });

  group('CompletionScreen — actions', () {
    testWidgets('Play Again dispatches PlayAgainRequested', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      // Scroll the button into view before tapping
      await tester.ensureVisible(find.text('Play Again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Again'));
      await tester.pump();

      verify(
        () => puzzleBloc.add(any(that: isA<PlayAgainRequested>())),
      ).called(1);
    });

    testWidgets('New Puzzle dispatches NewPuzzleRequested', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      await tester.ensureVisible(find.text('New Puzzle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Puzzle'));
      await tester.pump();

      verify(
        () => puzzleBloc.add(any(that: isA<NewPuzzleRequested>())),
      ).called(1);
    });
  });

  group('CompletionScreen — accessibility', () {
    testWidgets('Play Again button has Semantics label', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      // Find the Semantics widget wrapping the Play Again button
      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final playAgainSemantics = semanticsWidgets.where(
        (s) => s.properties.label == 'Play Again',
      );
      expect(playAgainSemantics, isNotEmpty);
    });

    testWidgets('New Puzzle button has Semantics label', (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final newPuzzleSemantics = semanticsWidgets.where(
        (s) => s.properties.label == 'New Puzzle',
      );
      expect(newPuzzleSemantics, isNotEmpty);
    });

    testWidgets('action buttons have minimum 44×44 touch targets',
        (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      whenListen(
        puzzleBloc,
        const Stream<PuzzleBlocState>.empty(),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));

      // The buttons are wrapped in SizedBox with width: double.infinity
      // and height: 48 (≥ 44 points). Verify via the SizedBox wrappers.
      // Find all SizedBox widgets with height 48 — these are our button
      // containers.
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.byType(SizedBox),
      );
      final buttonContainers =
          sizedBoxes.where((sb) => sb.height == 48).toList();
      expect(buttonContainers.length, greaterThanOrEqualTo(2));
      for (final sb in buttonContainers) {
        expect(sb.height, greaterThanOrEqualTo(44));
      }
    });
  });

  group('CompletionScreen — navigation', () {
    testWidgets('hides completion content when BoardActive is emitted',
        (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);
      final boardState = BoardActive(state: state);

      whenListen(
        puzzleBloc,
        Stream<PuzzleBlocState>.fromIterable([boardState]),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));
      await tester.pumpAndSettle();

      // When BoardActive is emitted the CompletionScreen's BlocBuilder
      // renders an empty SizedBox because state is no longer PuzzleSolved.
      expect(find.text('Puzzle Complete!'), findsNothing);
    });

    testWidgets('hides completion content when PuzzleInitial is emitted',
        (tester) async {
      final puzzleBloc = MockPuzzleBloc();
      final state = _solvedState(2);

      whenListen(
        puzzleBloc,
        Stream<PuzzleBlocState>.fromIterable([const PuzzleInitial()]),
        initialState: PuzzleSolved(
          state: state,
          moveCount: 5,
          elapsedSeconds: 30,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(puzzleBloc: puzzleBloc));
      await tester.pumpAndSettle();

      // When PuzzleInitial is emitted the CompletionScreen's BlocBuilder
      // renders an empty SizedBox because state is no longer PuzzleSolved.
      expect(find.text('Puzzle Complete!'), findsNothing);
    });
  });
}
