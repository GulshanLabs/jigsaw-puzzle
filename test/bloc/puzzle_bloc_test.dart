import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/exceptions.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

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

class MockImageProcessor implements ImageProcessor {
  List<Piece> Function(Uint8List, int)? processCallback;

  @override
  List<Piece> process(Uint8List imageBytes, int n) {
    if (processCallback != null) return processCallback!(imageBytes, n);
    return _defaultPieces(n);
  }

  static List<Piece> _defaultPieces(int n) {
    return [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++)
          Piece(id: PieceId(r, c), imageBytes: Uint8List.fromList([r, c])),
    ];
  }
}

class MockShuffleEngine implements ShuffleEngine {
  List<Piece> Function(List<Piece>)? shuffleCallback;

  @override
  List<Piece> shuffle(List<Piece> pieces) {
    if (shuffleCallback != null) return shuffleCallback!(pieces);
    // Default: reverse the list (guaranteed != solved for n >= 2).
    return pieces.reversed.toList();
  }
}

class MockWinDetector implements WinDetector {
  bool Function(PuzzleState)? isSolvedCallback;

  @override
  bool isSolved(PuzzleState state) {
    if (isSolvedCallback != null) return isSolvedCallback!(state);
    return state.isSolved;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _fakeImageBytes = Uint8List.fromList([1, 2, 3, 4]);

List<Piece> _makePieces(int n) => MockImageProcessor._defaultPieces(n);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PuzzleBloc', () {
    late MockPermissionService permissionService;
    late MockImagePickerService imagePickerService;
    late MockImageProcessor imageProcessor;
    late MockShuffleEngine shuffleEngine;
    late MockWinDetector winDetector;
    late TimerBloc timerBloc;

    setUp(() {
      permissionService = MockPermissionService();
      imagePickerService = MockImagePickerService();
      imageProcessor = MockImageProcessor();
      shuffleEngine = MockShuffleEngine();
      winDetector = MockWinDetector();
      timerBloc = TimerBloc();
    });

    tearDown(() {
      timerBloc.close();
    });

    PuzzleBloc buildBloc() => PuzzleBloc(
          permissionService: permissionService,
          imagePickerService: imagePickerService,
          imageProcessor: imageProcessor,
          shuffleEngine: shuffleEngine,
          winDetector: winDetector,
          timerBloc: timerBloc,
        );

    // 1. Initial state
    test('initial state is PuzzleInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const PuzzleInitial());
      bloc.close();
    });

    // 2. Camera - permission granted - image acquired
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PhotoSourceSelected camera: granted → PhotoAcquired → ConfiguringGrid',
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = _fakeImageBytes;
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PhotoSourceSelected(PhotoSource.camera)),
      expect: () => [
        PhotoAcquired(_fakeImageBytes),
        ConfiguringGrid(imageBytes: _fakeImageBytes),
      ],
    );

    // 3. Gallery - permission granted - image acquired
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PhotoSourceSelected gallery: granted → PhotoAcquired → ConfiguringGrid',
      build: () {
        permissionService.galleryResult = PermissionStatus.granted;
        imagePickerService.galleryResult = _fakeImageBytes;
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PhotoSourceSelected(PhotoSource.gallery)),
      expect: () => [
        PhotoAcquired(_fakeImageBytes),
        ConfiguringGrid(imageBytes: _fakeImageBytes),
      ],
    );

    // 4. Camera - permission denied
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PhotoSourceSelected camera: denied → PermissionDenied',
      build: () {
        permissionService.cameraResult = PermissionStatus.denied;
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PhotoSourceSelected(PhotoSource.camera)),
      expect: () => [
        const PermissionDenied(source: PhotoSource.camera, isPermanent: false),
      ],
    );

    // 5. Camera - permanently denied
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PhotoSourceSelected camera: permanentlyDenied → PermissionDenied(isPermanent: true)',
      build: () {
        permissionService.cameraResult = PermissionStatus.permanentlyDenied;
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PhotoSourceSelected(PhotoSource.camera)),
      expect: () => [
        const PermissionDenied(source: PhotoSource.camera, isPermanent: true),
      ],
    );

    // 6. User cancels picker
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PhotoSourceSelected: user cancels picker → stays at PuzzleInitial',
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = null; // cancelled
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PhotoSourceSelected(PhotoSource.camera)),
      expect: () => <PuzzleBlocState>[],
    );

    // 7. GridSizeSelected
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'GridSizeSelected → ConfiguringGrid with selectedN',
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = _fakeImageBytes;
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const PhotoSourceSelected(PhotoSource.camera));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeSelected(3));
      },
      expect: () => [
        PhotoAcquired(_fakeImageBytes),
        ConfiguringGrid(imageBytes: _fakeImageBytes),
        ConfiguringGrid(imageBytes: _fakeImageBytes, selectedN: 3),
      ],
    );

    // 8. GridSizeConfirmed → ProcessingImage → BoardActive
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'GridSizeConfirmed → ProcessingImage → BoardActive',
      wait: const Duration(milliseconds: 100),
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = _fakeImageBytes;
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const PhotoSourceSelected(PhotoSource.camera));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeSelected(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeConfirmed());
      },
      expect: () {
        final pieces = _makePieces(2);
        final shuffled = pieces.reversed.toList();
        final placement = <PieceId, BoardPosition>{};
        for (var i = 0; i < shuffled.length; i++) {
          placement[shuffled[i].id] = BoardPosition(i ~/ 2, i % 2);
        }
        final puzzleState = PuzzleState(
          gridSize: 2,
          sourceAspectRatio: 1.0,
          pieces: pieces,
          placement: placement,
        );
        return [
          PhotoAcquired(_fakeImageBytes),
          ConfiguringGrid(imageBytes: _fakeImageBytes),
          ConfiguringGrid(imageBytes: _fakeImageBytes, selectedN: 2),
          ProcessingImage(imageBytes: _fakeImageBytes, gridSize: 2),
          BoardActive(state: puzzleState),
        ];
      },
    );

    // 9. GridSizeConfirmed with processing error
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'GridSizeConfirmed with processing error → ImageProcessingError',
      wait: const Duration(milliseconds: 100),
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = _fakeImageBytes;
        imageProcessor.processCallback = (_, __) {
          throw const ImageProcessingException('test error');
        };
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const PhotoSourceSelected(PhotoSource.camera));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeSelected(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeConfirmed());
      },
      expect: () => [
        PhotoAcquired(_fakeImageBytes),
        ConfiguringGrid(imageBytes: _fakeImageBytes),
        ConfiguringGrid(imageBytes: _fakeImageBytes, selectedN: 2),
        ProcessingImage(imageBytes: _fakeImageBytes, gridSize: 2),
        const ImageProcessingError(),
      ],
    );

    // 10. PieceTapped - select a piece
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PieceTapped selects a piece → BoardActive with selectedPieceId',
      build: () => buildBloc(),
      seed: () {
        final pieces = _makePieces(2);
        final placement = <PieceId, BoardPosition>{
          for (var p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
        };
        return BoardActive(
          state: PuzzleState(gridSize: 2, sourceAspectRatio: 1.0, pieces: pieces, placement: placement),
        );
      },
      act: (bloc) => bloc.add(const PieceTapped(PieceId(0, 0))),
      expect: () {
        final pieces = _makePieces(2);
        final placement = <PieceId, BoardPosition>{
          for (var p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
        };
        return [
          BoardActive(
            state: PuzzleState(
                gridSize: 2, sourceAspectRatio: 1.0, pieces: pieces, placement: placement),
            selectedPieceId: const PieceId(0, 0),
          ),
        ];
      },
    );

    // 11. PieceTapped - tap same piece → deselect
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PieceTapped same piece → deselect (selectedPieceId null)',
      build: () => buildBloc(),
      seed: () {
        final pieces = _makePieces(2);
        final placement = <PieceId, BoardPosition>{
          for (var p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
        };
        return BoardActive(
          state: PuzzleState(gridSize: 2, sourceAspectRatio: 1.0, pieces: pieces, placement: placement),
          selectedPieceId: const PieceId(0, 0),
        );
      },
      act: (bloc) => bloc.add(const PieceTapped(PieceId(0, 0))),
      expect: () {
        final pieces = _makePieces(2);
        final placement = <PieceId, BoardPosition>{
          for (var p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
        };
        return [
          BoardActive(
            state: PuzzleState(
                gridSize: 2, sourceAspectRatio: 1.0, pieces: pieces, placement: placement),
          ),
        ];
      },
    );

    // 12. PieceTapped - tap different piece → swap, BoardActive with updated state
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PieceTapped different piece → swap, BoardActive with updated state',
      build: () {
        winDetector.isSolvedCallback = (_) => false;
        return buildBloc();
      },
      seed: () {
        final pieces = _makePieces(2);
        // Place pieces in non-solved positions.
        final placement = <PieceId, BoardPosition>{
          const PieceId(0, 0): const BoardPosition(1, 1),
          const PieceId(0, 1): const BoardPosition(0, 0),
          const PieceId(1, 0): const BoardPosition(0, 1),
          const PieceId(1, 1): const BoardPosition(1, 0),
        };
        return BoardActive(
          state: PuzzleState(gridSize: 2, sourceAspectRatio: 1.0, pieces: pieces, placement: placement),
          selectedPieceId: const PieceId(0, 0),
        );
      },
      act: (bloc) => bloc.add(const PieceTapped(PieceId(0, 1))),
      expect: () {
        final pieces = _makePieces(2);
        final placement = <PieceId, BoardPosition>{
          const PieceId(0, 0): const BoardPosition(1, 1),
          const PieceId(0, 1): const BoardPosition(0, 0),
          const PieceId(1, 0): const BoardPosition(0, 1),
          const PieceId(1, 1): const BoardPosition(1, 0),
        };
        final swapped = PuzzleState(
          gridSize: 2,
          sourceAspectRatio: 1.0,
          pieces: pieces,
          placement: placement,
        ).swap(const PieceId(0, 0), const PieceId(0, 1));
        return [
          BoardActive(state: swapped),
        ];
      },
    );

    // 13. PieceTapped - swap that solves puzzle → PuzzleSolved
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PieceTapped swap that solves puzzle → PuzzleSolved',
      build: () {
        winDetector.isSolvedCallback = (_) => true;
        return buildBloc();
      },
      seed: () {
        final pieces = _makePieces(2);
        // Only two pieces are swapped — one more swap solves it.
        final placement = <PieceId, BoardPosition>{
          const PieceId(0, 0): const BoardPosition(0, 1),
          const PieceId(0, 1): const BoardPosition(0, 0),
          const PieceId(1, 0): const BoardPosition(1, 0),
          const PieceId(1, 1): const BoardPosition(1, 1),
        };
        return BoardActive(
          state: PuzzleState(
            gridSize: 2,
            sourceAspectRatio: 1.0,
            pieces: pieces,
            placement: placement,
            moveCount: 5,
          ),
          selectedPieceId: const PieceId(0, 0),
        );
      },
      act: (bloc) => bloc.add(const PieceTapped(PieceId(0, 1))),
      expect: () {
        final pieces = _makePieces(2);
        final placement = <PieceId, BoardPosition>{
          const PieceId(0, 0): const BoardPosition(0, 1),
          const PieceId(0, 1): const BoardPosition(0, 0),
          const PieceId(1, 0): const BoardPosition(1, 0),
          const PieceId(1, 1): const BoardPosition(1, 1),
        };
        final swapped = PuzzleState(
          gridSize: 2,
          sourceAspectRatio: 1.0,
          pieces: pieces,
          placement: placement,
          moveCount: 5,
        ).swap(const PieceId(0, 0), const PieceId(0, 1));
        return [
          PuzzleSolved(
            state: swapped,
            moveCount: swapped.moveCount,
            elapsedSeconds: 0,
          ),
        ];
      },
    );

    // 14. PlayAgainRequested → BoardActive with moveCount=0, timer reset
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'PlayAgainRequested → BoardActive with moveCount=0',
      wait: const Duration(milliseconds: 100),
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = _fakeImageBytes;
        return buildBloc();
      },
      act: (bloc) async {
        // Set up a full game first.
        bloc.add(const PhotoSourceSelected(PhotoSource.camera));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeSelected(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeConfirmed());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc.add(const PlayAgainRequested());
      },
      verify: (bloc) {
        final finalState = bloc.state;
        expect(finalState, isA<BoardActive>());
        expect((finalState as BoardActive).state.moveCount, 0);
      },
    );

    // 15. NewPuzzleRequested → PuzzleInitial, timer reset
    blocTest<PuzzleBloc, PuzzleBlocState>(
      'NewPuzzleRequested → PuzzleInitial',
      wait: const Duration(milliseconds: 100),
      build: () {
        permissionService.cameraResult = PermissionStatus.granted;
        imagePickerService.cameraResult = _fakeImageBytes;
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const PhotoSourceSelected(PhotoSource.camera));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeSelected(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GridSizeConfirmed());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc.add(const GridSizeConfirmed());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NewPuzzleRequested());
      },
      verify: (bloc) {
        expect(bloc.state, const PuzzleInitial());
      },
    );
  });
}
