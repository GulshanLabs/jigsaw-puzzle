import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/ui/screens/grid_config_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/photo_source_screen.dart';

// ---------------------------------------------------------------------------
// Manual mock classes (same pattern as puzzle_bloc_test.dart)
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

class MockImageProcessor implements ImageProcessor {
  @override
  List<Piece> process(Uint8List imageBytes, int n) {
    return [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++)
          Piece(id: PieceId(r, c), imageBytes: Uint8List.fromList([r, c])),
    ];
  }
}

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

/// App shell that drives navigation based on PuzzleBloc state.
class _TestAppShell extends StatelessWidget {
  const _TestAppShell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PuzzleBloc, PuzzleBlocState>(
      builder: (context, state) {
        if (state is ConfiguringGrid || state is ProcessingImage) {
          return const GridConfigScreen(key: ValueKey('grid'));
        }
        // PuzzleInitial, PhotoAcquired, PermissionDenied — show source screen.
        return const PhotoSourceScreen(key: ValueKey('home'));
      },
    );
  }
}

/// Creates all mocks and the bloc inside the testWidgets callback (required
/// so that async event handlers run in the FakeAsync zone).
///
/// Returns a record with all the pieces needed for assertions.
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
  group('Camera permission flows', () {
    testWidgets(
      'granted → camera picker opens → image acquired → navigates to grid config',
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

        // Verify PhotoSourceScreen is shown initially.
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);

        // Tap "Take a Photo".
        await tester.tap(find.text('Take a Photo'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Should navigate to GridConfigScreen.
        expect(find.text('Configure Puzzle'), findsOneWidget);
      },
    );

    testWidgets(
      'denied → PermissionDenied dialog shown with Open Settings option',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.cameraResult = PermissionStatus.denied;

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Tap "Take a Photo".
        await tester.tap(find.text('Take a Photo'));
        await tester.pump();
        await tester.pump();

        // Should show permission denied dialog.
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Verify the dialog message mentions camera.
        expect(
          find.textContaining('camera'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'permanently denied → PermissionDenied dialog directing to settings',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.cameraResult = PermissionStatus.permanentlyDenied;

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Tap "Take a Photo".
        await tester.tap(find.text('Take a Photo'));
        await tester.pump();
        await tester.pump();

        // Should show permission denied dialog.
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);

        // Verify the dialog message mentions permanently denied / settings.
        expect(
          find.textContaining('permanently denied'),
          findsOneWidget,
        );

        // Tap "Open Settings" and verify it calls openAppSettings.
        await tester.tap(find.text('Open Settings'));
        await tester.pump();
        await tester.pump();

        expect(h.permissionService.openSettingsCalled, isTrue);
      },
    );
  });

  group('Gallery permission flows', () {
    testWidgets(
      'granted → gallery picker opens → image acquired → navigates to grid config',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.galleryResult = PermissionStatus.granted;
        h.imagePickerService.galleryResult = _whitePng();

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Tap "Choose from Gallery".
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Should navigate to GridConfigScreen.
        expect(find.text('Configure Puzzle'), findsOneWidget);
      },
    );

    testWidgets(
      'denied → PermissionDenied dialog shown',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.galleryResult = PermissionStatus.denied;

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Tap "Choose from Gallery".
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pump();
        await tester.pump();

        // Should show permission denied dialog.
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Verify the dialog message mentions photo library.
        expect(
          find.textContaining('photo library'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'permanently denied → PermissionDenied dialog directing to settings',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.galleryResult = PermissionStatus.permanentlyDenied;

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Tap "Choose from Gallery".
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pump();
        await tester.pump();

        // Should show permission denied dialog.
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);

        // Verify the dialog message mentions permanently denied / settings.
        expect(
          find.textContaining('permanently denied'),
          findsOneWidget,
        );

        // Tap "Open Settings" and verify it calls openAppSettings.
        await tester.tap(find.text('Open Settings'));
        await tester.pump();
        await tester.pump();

        expect(h.permissionService.openSettingsCalled, isTrue);
      },
    );
  });

  group('User cancels picker', () {
    testWidgets(
      'camera picker cancelled → stays on photo source selection screen',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.cameraResult = PermissionStatus.granted;
        h.imagePickerService.cameraResult = null; // user cancelled

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Verify PhotoSourceScreen is shown initially.
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);

        // Tap "Take a Photo".
        await tester.tap(find.text('Take a Photo'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Should remain on PhotoSourceScreen — no navigation.
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
        // Should NOT navigate to GridConfigScreen.
        expect(find.text('Configure Puzzle'), findsNothing);
      },
    );

    testWidgets(
      'gallery picker cancelled → stays on photo source selection screen',
      (tester) async {
        final h = _createTestHarness();
        addTearDown(() {
          h.puzzleBloc.close();
          h.timerBloc.close();
        });

        h.permissionService.galleryResult = PermissionStatus.granted;
        h.imagePickerService.galleryResult = null; // user cancelled

        await tester.pumpWidget(h.app);
        await tester.pumpAndSettle();

        // Verify PhotoSourceScreen is shown initially.
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);

        // Tap "Choose from Gallery".
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Should remain on PhotoSourceScreen — no navigation.
        expect(find.text('Take a Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
        // Should NOT navigate to GridConfigScreen.
        expect(find.text('Configure Puzzle'), findsNothing);
      },
    );
  });
}
