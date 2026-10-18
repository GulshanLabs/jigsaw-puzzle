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
// Manual mock classes
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

/// App shell that mirrors main.dart's _AppShell, routing to all screens
/// including BoardScreen and CompletionScreen.
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('End-to-end puzzle session', () {
    testWidgets(
      'full flow: photo source → grid config → board → solve → completion',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        // Configure mocks: camera permission granted, camera returns image.
        h.permissionService.cameraResult = PermissionStatus.granted;
        h.imagePickerService.cameraResult = _whitePng();

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // --- Step 1: PhotoSourceScreen ---
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);

        // Tap "Take a Photo" to acquire image.
        await tester.tap(find.text('Take a Photo'));
        await tester.pumpAndSettle();

        // --- Step 2: GridConfigScreen ---
        expect(find.text('Configure Puzzle'), findsOneWidget);

        // Select 2×2 grid size.
        await tester.tap(find.text('2×2'));
        await tester.pumpAndSettle();

        // Confirm grid size selection.
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        // --- Step 3: BoardScreen ---
        expect(find.text('Solve the Puzzle'), findsOneWidget);

        // Verify move count starts at 0.
        expect(find.text('Moves: 0'), findsOneWidget);

        // Verify timer is displayed (starts at 00:00).
        expect(find.text('Time: 00:00'), findsOneWidget);

        // Advance time by 3 seconds so the timer shows a non-zero value.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // --- Step 4: Solve the puzzle via PieceTapped events ---
        // After reverse shuffle of 2×2:
        //   PieceId(1,1) at BoardPosition(0,0)
        //   PieceId(1,0) at BoardPosition(0,1)
        //   PieceId(0,1) at BoardPosition(1,0)
        //   PieceId(0,0) at BoardPosition(1,1)
        //
        // Swap 1: Tap piece (1,1) then piece (0,0) — swaps their positions.
        //   After: PieceId(0,0) at (0,0), PieceId(1,1) at (1,1)
        // Swap 2: Tap piece (1,0) then piece (0,1) — swaps their positions.
        //   After: PieceId(0,1) at (0,1), PieceId(1,0) at (1,0) → SOLVED!

        // Swap 1: Select piece (1,1), then tap piece (0,0).
        h.puzzleBloc.add(const PieceTapped(PieceId(1, 1)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(0, 0)));
        await tester.pump();
        await tester.pump();

        // Verify move count is now 1.
        expect(find.text('Moves: 1'), findsOneWidget);

        // Swap 2: Select piece (1,0), then tap piece (0,1).
        h.puzzleBloc.add(const PieceTapped(PieceId(1, 0)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(0, 1)));
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // --- Step 5: CompletionScreen ---
        expect(find.text('Puzzle Complete!'), findsOneWidget);

        // Verify the correct move count is displayed (2 swaps).
        expect(find.text('2'), findsOneWidget);

        // Verify "Moves" and "Time" labels are shown.
        expect(find.text('Moves'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);

        // Verify action buttons are present.
        expect(find.text('Play Again'), findsOneWidget);
        expect(find.text('New Puzzle'), findsOneWidget);

        // Verify the reconstructed image is displayed (Image.memory widgets).
        expect(find.byType(Image), findsWidgets);
      },
    );

    testWidgets(
      'move count is accurate after multiple swaps',
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

        // Navigate to board: Take photo → select 2×2 → confirm.
        await tester.tap(find.text('Take a Photo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('2×2'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(find.text('Solve the Puzzle'), findsOneWidget);
        expect(find.text('Moves: 0'), findsOneWidget);

        // Perform a swap that does NOT solve the puzzle.
        // Swap piece (1,1) with piece (1,0).
        h.puzzleBloc.add(const PieceTapped(PieceId(1, 1)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(1, 0)));
        await tester.pump();
        await tester.pump();

        // Move count should be 1.
        expect(find.text('Moves: 1'), findsOneWidget);

        // Swap them back.
        h.puzzleBloc.add(const PieceTapped(PieceId(1, 1)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(1, 0)));
        await tester.pump();
        await tester.pump();

        // Move count should be 2.
        expect(find.text('Moves: 2'), findsOneWidget);

        // Now solve: swap (1,1) with (0,0), then (1,0) with (0,1).
        h.puzzleBloc.add(const PieceTapped(PieceId(1, 1)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(0, 0)));
        await tester.pump();
        await tester.pump();

        expect(find.text('Moves: 3'), findsOneWidget);

        h.puzzleBloc.add(const PieceTapped(PieceId(1, 0)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(0, 1)));
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // Should be on completion screen with 4 total moves.
        expect(find.text('Puzzle Complete!'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
      },
    );

    testWidgets(
      'timer value is displayed on completion screen',
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

        // Navigate to board.
        await tester.tap(find.text('Take a Photo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('2×2'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(find.text('Solve the Puzzle'), findsOneWidget);

        // Let the timer tick for 5 seconds.
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pump();

        // Solve the puzzle.
        h.puzzleBloc.add(const PieceTapped(PieceId(1, 1)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(0, 0)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(1, 0)));
        await tester.pump();
        await tester.pump();

        h.puzzleBloc.add(const PieceTapped(PieceId(0, 1)));
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // Should be on completion screen.
        expect(find.text('Puzzle Complete!'), findsOneWidget);

        // Verify elapsed time is shown.
        expect(find.text('Time'), findsOneWidget);

        // The elapsed seconds are captured by PuzzleBloc from
        // TimerBloc.state.seconds at the moment of solving.
        final elapsedSeconds = h.timerBloc.state.seconds;
        final minutes = elapsedSeconds ~/ 60;
        final secs = elapsedSeconds % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        expect(find.text(formatted), findsOneWidget);
      },
    );
  });
}
