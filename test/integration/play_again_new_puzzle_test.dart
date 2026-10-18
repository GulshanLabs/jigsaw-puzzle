import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/ui/screens/board_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/completion_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/grid_config_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/photo_source_screen.dart';

// ---------------------------------------------------------------------------
// Manual mock classes (same pattern as end_to_end_puzzle_test.dart)
// ---------------------------------------------------------------------------

class MockPermissionService implements PermissionService {
  PermissionStatus cameraResult = PermissionStatus.granted;
  PermissionStatus galleryResult = PermissionStatus.granted;
  bool openSettingsCalled = false;

  @override
  Future<PermissionStatus> requestCameraPermission() async => cameraResult;

  @override
  Future<PermissionStatus> requestGalleryPermission() async => galleryResult;

  @override
  Future<void> openAppSettings() async {
    openSettingsCalled = true;
  }
}

class MockImagePickerService implements ImagePickerService {
  Uint8List? cameraResult;
  Uint8List? galleryResult;

  @override
  Future<Uint8List?> pickFromCamera() async => cameraResult;

  @override
  Future<Uint8List?> pickFromGallery() async => galleryResult;
}

/// Mock image processor that produces pieces with valid PNG image bytes.
class MockImageProcessor implements ImageProcessor {
  @override
  List<Piece> process(Uint8List imageBytes, int n) {
    final png = _whitePng();
    return [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++)
          Piece(id: PieceId(r, c), imageBytes: png),
    ];
  }
}

/// Deterministic shuffle: reverses the piece list so the result is predictable.
/// For a 2×2 grid with pieces [(0,0), (0,1), (1,0), (1,1)], reversing gives
/// [(1,1), (1,0), (0,1), (0,0)], producing placement:
///   PieceId(1,1) → BoardPosition(0,0)
///   PieceId(1,0) → BoardPosition(0,1)
///   PieceId(0,1) → BoardPosition(1,0)
///   PieceId(0,0) → BoardPosition(1,1)
class MockShuffleEngine implements ShuffleEngine {
  @override
  List<Piece> shuffle(List<Piece> pieces) => pieces.reversed.toList();
}

class MockWinDetector implements WinDetector {
  @override
  bool isSolved(PuzzleState state) => state.isSolved;
}

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

/// App shell that mirrors main.dart's _AppShell, routing to all screens.
class _TestAppShell extends StatelessWidget {
  const _TestAppShell();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PuzzleBloc, PuzzleBlocState>(
      listener: (context, state) {
        final timerBloc = context.read<TimerBloc>();
        if (state is PuzzleSolved) {
          if (timerBloc.state is! TimerStopped) {
            timerBloc.add(const TimerStopRequested());
          }
        }
      },
      child: BlocBuilder<PuzzleBloc, PuzzleBlocState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screenForState(state),
          );
        },
      ),
    );
  }

  Widget _screenForState(PuzzleBlocState state) {
    if (state is ConfiguringGrid || state is ProcessingImage) {
      return const GridConfigScreen(key: ValueKey('grid'));
    }
    if (state is ImageProcessingError) {
      return const PhotoSourceScreen(key: ValueKey('home'));
    }
    if (state is BoardActive) {
      return const BoardScreen(key: ValueKey('board'));
    }
    if (state is PuzzleSolved) {
      return const CompletionScreen(key: ValueKey('completion'));
    }
    return const PhotoSourceScreen(key: ValueKey('home'));
  }
}

/// Creates all mocks and the bloc inside the testWidgets callback.
({
  MockPermissionService permissionService,
  MockImagePickerService imagePickerService,
  PuzzleBloc puzzleBloc,
  TimerBloc timerBloc,
  Widget app,
}) _createTestHarness() {
  final permissionService = MockPermissionService();
  final imagePickerService = MockImagePickerService();
  final timerBloc = TimerBloc();
  final puzzleBloc = PuzzleBloc(
    permissionService: permissionService,
    imagePickerService: imagePickerService,
    imageProcessor: MockImageProcessor(),
    shuffleEngine: MockShuffleEngine(),
    winDetector: MockWinDetector(),
    timerBloc: timerBloc,
  );

  final app = RepositoryProvider<PermissionService>.value(
    value: permissionService,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<TimerBloc>.value(value: timerBloc),
        BlocProvider<PuzzleBloc>.value(value: puzzleBloc),
      ],
      child: const MaterialApp(
        home: _TestAppShell(),
      ),
    ),
  );

  return (
    permissionService: permissionService,
    imagePickerService: imagePickerService,
    puzzleBloc: puzzleBloc,
    timerBloc: timerBloc,
    app: app,
  );
}

/// Helper: navigates from PhotoSourceScreen through to BoardScreen with a 2×2 grid.
Future<void> _navigateToBoard(WidgetTester tester, dynamic h) async {
  await tester.tap(find.text('Take a Photo'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('2×2'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

/// Helper: solves the 2×2 puzzle using the deterministic reverse-shuffle pattern.
/// Swap 1: PieceTapped(1,1) then PieceTapped(0,0)
/// Swap 2: PieceTapped(1,0) then PieceTapped(0,1)
Future<void> _solvePuzzle(WidgetTester tester, PuzzleBloc puzzleBloc) async {
  puzzleBloc.add(const PieceTapped(PieceId(1, 1)));
  await tester.pump();
  await tester.pump();

  puzzleBloc.add(const PieceTapped(PieceId(0, 0)));
  await tester.pump();
  await tester.pump();

  puzzleBloc.add(const PieceTapped(PieceId(1, 0)));
  await tester.pump();
  await tester.pump();

  puzzleBloc.add(const PieceTapped(PieceId(0, 1)));
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Play Again flow', () {
    testWidgets(
      'Play Again resets move count and timer, reuses same image and grid size',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.cameraResult = PermissionStatus.granted;
        h.imagePickerService.cameraResult = _whitePng();

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // --- Navigate to board and solve ---
        await _navigateToBoard(tester, h);
        expect(find.text('Solve the Puzzle'), findsOneWidget);
        expect(find.text('Moves: 0'), findsOneWidget);

        // Let timer tick a few seconds before solving.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // Solve the puzzle (2 moves).
        await _solvePuzzle(tester, h.puzzleBloc);

        // --- Verify completion screen ---
        expect(find.text('Puzzle Complete!'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // 2 moves
        expect(find.text('Play Again'), findsOneWidget);

        // --- Tap "Play Again" (scroll into view first — button may be off-screen) ---
        await tester.ensureVisible(find.text('Play Again'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Play Again'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // --- Verify we're back on BoardScreen ---
        expect(find.text('Solve the Puzzle'), findsOneWidget);

        // Verify move count is reset to 0.
        expect(find.text('Moves: 0'), findsOneWidget);

        // Verify timer is reset to 00:00.
        expect(find.text('Time: 00:00'), findsOneWidget);

        // Verify the same grid size (2×2) is used — 4 pieces on board.
        // The board should have 4 PuzzlePieceWidget instances (rendered as
        // Image.memory widgets inside the grid).
        final puzzleState = h.puzzleBloc.state;
        expect(puzzleState, isA<BoardActive>());
        final boardActive = puzzleState as BoardActive;
        expect(boardActive.state.gridSize, equals(2));
        expect(boardActive.state.pieces.length, equals(4));
        expect(boardActive.state.moveCount, equals(0));

        // Verify the puzzle is re-shuffled (pieces NOT in solved positions).
        // With MockShuffleEngine (reverse), piece (0,0) should NOT be at
        // BoardPosition(0,0).
        expect(boardActive.state.isSolved, isFalse);

        // Verify we can solve again with the same swap sequence.
        await _solvePuzzle(tester, h.puzzleBloc);
        expect(find.text('Puzzle Complete!'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // 2 moves again
      },
    );
  });

  group('New Puzzle flow', () {
    testWidgets(
      'New Puzzle returns to source selection and clears state',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.cameraResult = PermissionStatus.granted;
        h.imagePickerService.cameraResult = _whitePng();

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // --- Navigate to board and solve ---
        await _navigateToBoard(tester, h);
        expect(find.text('Solve the Puzzle'), findsOneWidget);

        await _solvePuzzle(tester, h.puzzleBloc);

        // --- Verify completion screen ---
        expect(find.text('Puzzle Complete!'), findsOneWidget);
        expect(find.text('New Puzzle'), findsOneWidget);

        // --- Tap "New Puzzle" (scroll into view first — button may be off-screen) ---
        await tester.ensureVisible(find.text('New Puzzle'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Puzzle'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // --- Verify we're back on PhotoSourceScreen ---
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);

        // Verify the state is cleared (PuzzleInitial).
        expect(h.puzzleBloc.state, isA<PuzzleInitial>());

        // Verify board and completion screens are gone.
        expect(find.text('Solve the Puzzle'), findsNothing);
        expect(find.text('Puzzle Complete!'), findsNothing);
      },
    );
  });
}
