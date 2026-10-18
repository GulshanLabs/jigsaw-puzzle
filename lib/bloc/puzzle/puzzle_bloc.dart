import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/exceptions.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

import 'puzzle_event.dart';
import 'puzzle_state.dart';

export 'puzzle_event.dart';
export 'puzzle_state.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleBlocState> {
  final PermissionService _permissionService;
  final ImagePickerService _imagePickerService;
  final ImageProcessor _imageProcessor;
  final ShuffleEngine _shuffleEngine;
  final WinDetector _winDetector;
  final TimerBloc _timerBloc;

  /// Stored for PlayAgain support.
  Uint8List? _imageBytes;
  int? _gridSize;
  double? _sourceAspectRatio;

  PuzzleBloc({
    required PermissionService permissionService,
    required ImagePickerService imagePickerService,
    required ImageProcessor imageProcessor,
    required ShuffleEngine shuffleEngine,
    required WinDetector winDetector,
    required TimerBloc timerBloc,
  })  : _permissionService = permissionService,
        _imagePickerService = imagePickerService,
        _imageProcessor = imageProcessor,
        _shuffleEngine = shuffleEngine,
        _winDetector = winDetector,
        _timerBloc = timerBloc,
        super(const PuzzleInitial()) {
    on<PhotoSourceSelected>(_onPhotoSourceSelected);
    on<GridSizeSelected>(_onGridSizeSelected);
    on<GridSizeConfirmed>(_onGridSizeConfirmed);
    on<PieceTapped>(_onPieceTapped);
    on<PlayAgainRequested>(_onPlayAgainRequested);
    on<NewPuzzleRequested>(_onNewPuzzleRequested);
  }

  Future<void> _onPhotoSourceSelected(
    PhotoSourceSelected event,
    Emitter<PuzzleBlocState> emit,
  ) async {
    final PermissionStatus status;
    if (event.source == PhotoSource.camera) {
      status = await _permissionService.requestCameraPermission();
    } else {
      status = await _permissionService.requestGalleryPermission();
    }

    if (status == PermissionStatus.denied) {
      emit(PermissionDenied(source: event.source, isPermanent: false));
      return;
    }
    if (status == PermissionStatus.permanentlyDenied) {
      emit(PermissionDenied(source: event.source, isPermanent: true));
      return;
    }

    // Permission granted — pick image.
    final Uint8List? bytes;
    if (event.source == PhotoSource.camera) {
      bytes = await _imagePickerService.pickFromCamera();
    } else {
      bytes = await _imagePickerService.pickFromGallery();
    }

    if (bytes == null) {
      // User cancelled the picker — stay on current state.
      return;
    }

    _imageBytes = bytes;
    emit(PhotoAcquired(bytes));
    emit(ConfiguringGrid(imageBytes: bytes));
  }

  void _onGridSizeSelected(
    GridSizeSelected event,
    Emitter<PuzzleBlocState> emit,
  ) {
    if (_imageBytes == null) return;
    _gridSize = event.n;
    emit(ConfiguringGrid(
      imageBytes: _imageBytes!,
      selectedN: event.n,
    ));
  }

  Future<void> _onGridSizeConfirmed(
    GridSizeConfirmed event,
    Emitter<PuzzleBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConfiguringGrid || currentState.selectedN == null) {
      return;
    }

    final n = currentState.selectedN!;
    _gridSize = n;

    emit(ProcessingImage(imageBytes: _imageBytes!, gridSize: n));

    // Yield to the event loop so the UI can render the loading indicator
    // before the synchronous image processing blocks the main isolate.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    try {
      final pieces = _imageProcessor.process(_imageBytes!, n);

      // Decode image to compute source aspect ratio.
      double sourceAspectRatio;
      try {
        final decoded = img.decodeImage(_imageBytes!);
        sourceAspectRatio =
            decoded != null ? decoded.width / decoded.height : 1.0;
      } catch (_) {
        sourceAspectRatio = 1.0;
      }
      _sourceAspectRatio = sourceAspectRatio;

      final shuffled = _shuffleEngine.shuffle(pieces);
      final placement = _buildPlacement(shuffled, n);

      final puzzleState = PuzzleState(
        gridSize: n,
        sourceAspectRatio: sourceAspectRatio,
        pieces: pieces,
        placement: placement,
        moveCount: 0,
      );

      _timerBloc.add(const TimerStarted());
      emit(BoardActive(state: puzzleState));
    } on ImageProcessingException {
      emit(const ImageProcessingError());
    }
  }

  void _onPieceTapped(
    PieceTapped event,
    Emitter<PuzzleBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! BoardActive) return;

    final selectedId = currentState.selectedPieceId;

    if (selectedId == null) {
      // No piece selected — select this one.
      emit(BoardActive(
        state: currentState.state,
        selectedPieceId: event.pieceId,
      ));
      return;
    }

    if (selectedId == event.pieceId) {
      // Same piece tapped — deselect.
      emit(BoardActive(state: currentState.state));
      return;
    }

    // Different piece tapped — swap.
    final newPuzzleState = currentState.state.swap(selectedId, event.pieceId);

    if (_winDetector.isSolved(newPuzzleState)) {
      _timerBloc.add(const TimerStopRequested());
      emit(PuzzleSolved(
        state: newPuzzleState,
        moveCount: newPuzzleState.moveCount,
        elapsedSeconds: _timerBloc.state.seconds,
      ));
      return;
    }

    emit(BoardActive(state: newPuzzleState));
  }

  void _onPlayAgainRequested(
    PlayAgainRequested event,
    Emitter<PuzzleBlocState> emit,
  ) {
    if (_imageBytes == null || _gridSize == null) return;

    final currentState = state;
    final List<Piece> pieces;
    if (currentState is BoardActive) {
      pieces = currentState.state.pieces;
    } else if (currentState is PuzzleSolved) {
      pieces = currentState.state.pieces;
    } else {
      return;
    }

    final n = _gridSize!;
    final sourceAspectRatio = _sourceAspectRatio ?? 1.0;
    final shuffled = _shuffleEngine.shuffle(pieces);
    final placement = _buildPlacement(shuffled, n);

    final puzzleState = PuzzleState(
      gridSize: n,
      sourceAspectRatio: sourceAspectRatio,
      pieces: pieces,
      placement: placement,
      moveCount: 0,
    );

    _timerBloc.add(const TimerReset());
    _timerBloc.add(const TimerStarted());
    emit(BoardActive(state: puzzleState));
  }

  void _onNewPuzzleRequested(
    NewPuzzleRequested event,
    Emitter<PuzzleBlocState> emit,
  ) {
    _timerBloc.add(const TimerReset());
    _imageBytes = null;
    _gridSize = null;
    _sourceAspectRatio = null;
    emit(const PuzzleInitial());
  }

  /// Builds a placement map from a shuffled list of pieces.
  Map<PieceId, BoardPosition> _buildPlacement(
    List<Piece> shuffled,
    int n,
  ) {
    final placement = <PieceId, BoardPosition>{};
    for (var i = 0; i < shuffled.length; i++) {
      placement[shuffled[i].id] = BoardPosition(i ~/ n, i % n);
    }
    return placement;
  }
}
