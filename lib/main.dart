import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/audio_settings/audio_settings_cubit.dart';
import 'package:jigsaw_puzzle_game/bloc/theme/theme_cubit.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/image_processor.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/shuffle_engine.dart';
import 'package:jigsaw_puzzle_game/domain/win_detector.dart';
import 'package:jigsaw_puzzle_game/services/audio_service.dart';
import 'package:jigsaw_puzzle_game/services/image_picker_service.dart';
import 'package:jigsaw_puzzle_game/services/permission_service.dart';
import 'package:jigsaw_puzzle_game/services/preferences_repository.dart';
import 'package:jigsaw_puzzle_game/ui/screens/board_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/completion_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/grid_config_screen.dart';
import 'package:jigsaw_puzzle_game/ui/screens/photo_source_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(JigsawPuzzleApp(sharedPreferences: prefs));
}

class JigsawPuzzleApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const JigsawPuzzleApp({super.key, required this.sharedPreferences});

  @override
  State<JigsawPuzzleApp> createState() => _JigsawPuzzleAppState();
}

class _JigsawPuzzleAppState extends State<JigsawPuzzleApp> {
  late final PermissionService _permissionService;
  late final ImagePickerService _imagePickerService;
  late final ImageProcessor _imageProcessor;
  late final ShuffleEngine _shuffleEngine;
  late final WinDetector _winDetector;
  late final TimerBloc _timerBloc;
  late final PuzzleBloc _puzzleBloc;
  late final PreferencesRepository _preferencesRepository;
  late final AudioService _audioService;
  late final AudioSettingsCubit _audioSettingsCubit;
  late final ThemeCubit _themeCubit;

  @override
  void initState() {
    super.initState();
    _permissionService = PermissionServiceImpl();
    _imagePickerService = ImagePickerServiceImpl();
    _imageProcessor = ImageProcessorImpl();
    _shuffleEngine = ShuffleEngineImpl();
    _winDetector = WinDetectorImpl();
    _timerBloc = TimerBloc();
    _puzzleBloc = PuzzleBloc(
      permissionService: _permissionService,
      imagePickerService: _imagePickerService,
      imageProcessor: _imageProcessor,
      shuffleEngine: _shuffleEngine,
      winDetector: _winDetector,
      timerBloc: _timerBloc,
    );
    _preferencesRepository = PreferencesRepositoryImpl(widget.sharedPreferences);
    _audioService = AudioServiceImpl();
    _audioSettingsCubit = AudioSettingsCubit(
      preferencesRepository: _preferencesRepository,
      audioService: _audioService,
    );
    _audioSettingsCubit.init();
    _themeCubit = ThemeCubit(preferencesRepository: _preferencesRepository);
    _themeCubit.init();
  }

  @override
  void dispose() {
    _themeCubit.close();
    _audioSettingsCubit.close();
    _audioService.dispose();
    _puzzleBloc.close();
    _timerBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PermissionService>.value(value: _permissionService),
        RepositoryProvider<AudioService>.value(value: _audioService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TimerBloc>.value(value: _timerBloc),
          BlocProvider<PuzzleBloc>.value(value: _puzzleBloc),
          BlocProvider<AudioSettingsCubit>.value(value: _audioSettingsCubit),
          BlocProvider<ThemeCubit>.value(value: _themeCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Jigsaw Puzzle',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeState.theme.seedColor,
                  brightness: themeState.theme.brightness,
                ),
                useMaterial3: true,
              ),
              home: const _AppShell(),
            );
          },
        ),
      ),
    );
  }
}

/// Root shell that listens to [PuzzleBloc] state and drives navigation.
///
/// Uses a [BlocListener] to start/stop the [TimerBloc] at the right moments,
/// and a [BlocBuilder] to swap the active screen based on the current state.
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PuzzleBloc, PuzzleBlocState>(
      listener: (context, state) {
        final timerBloc = context.read<TimerBloc>();

        if (state is BoardActive) {
          // Start the timer when the board first becomes active.
          // Only start if the timer is not already running (avoids restarting
          // on every piece-tap rebuild).
          if (timerBloc.state is! TimerRunning ||
              timerBloc.state.seconds == 0) {
            // Timer is already started by PuzzleBloc on GridSizeConfirmed /
            // PlayAgainRequested, but this acts as a safety net.
          }
        }

        if (state is PuzzleSolved) {
          // Ensure the timer is stopped when the puzzle is solved.
          // PuzzleBloc already dispatches TimerStopRequested, but this
          // guarantees it from the UI layer as well.
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
      // Route back to source selection on processing error.
      // The GridConfigScreen shows a snackbar, but the requirement says
      // to return to the photo source selection screen.
      return const PhotoSourceScreen(key: ValueKey('home'));
    }
    if (state is BoardActive) {
      return const BoardScreen(key: ValueKey('board'));
    }
    if (state is PuzzleSolved) {
      return const CompletionScreen(key: ValueKey('completion'));
    }
    // PuzzleInitial, PhotoAcquired, PermissionDenied — all show source screen.
    return const PhotoSourceScreen(key: ValueKey('home'));
  }
}
