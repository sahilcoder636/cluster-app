import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/puzzle.dart';
import '../../data/repositories/pack_repository.dart';

part 'game_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase enum
// ─────────────────────────────────────────────────────────────────────────────

enum GamePhase {
  /// No tiles selected; waiting for player input.
  idle,

  /// 1–4 tiles selected; submit enabled at exactly 4.
  selecting,

  /// All 4 groups correctly found — game won.
  solved,

  /// 4 mistakes used — game lost.
  failed,
}

// ─────────────────────────────────────────────────────────────────────────────
// GameSource
// ─────────────────────────────────────────────────────────────────────────────

/// Indicates how the game was launched.
enum GameSource {
  /// Today's daily challenge.
  daily,

  /// A puzzle from a practice pack.
  pack,
}

// ─────────────────────────────────────────────────────────────────────────────
// GameState
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the current game.
class GameState {
  const GameState({
    this.puzzle,
    this.remainingWords = const [],
    this.selectedWords = const [],
    this.revealedGroups = const [],
    this.mistakeCount = 0,
    this.phase = GamePhase.idle,
    this.shouldShake = false,
    this.isOneAway = false,
    this.solveSequence = const [],
  });

  /// The puzzle being played (null before [GameNotifier.loadPuzzle] is called).
  final Puzzle? puzzle;

  /// Words still visible in the 4×4 grid (shuffled on load).
  final List<String> remainingWords;

  /// Words currently highlighted by the player (max 4).
  final List<String> selectedWords;

  /// Groups revealed so far, in reveal order.
  final List<PuzzleGroup> revealedGroups;

  /// Number of wrong guesses (0–4).
  final int mistakeCount;

  final GamePhase phase;

  /// True for one frame-cycle after a wrong guess — triggers shake animation.
  final bool shouldShake;

  /// True when 3 of the 4 selected words belong to a single unrevealed group.
  final bool isOneAway;

  /// Groups in the order they were solved (used for share-grid generation).
  final List<PuzzleGroup> solveSequence;

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get canSubmit => selectedWords.length == 4 && !shouldShake;

  int get groupsFound => revealedGroups.length;

  // ── copyWith ──────────────────────────────────────────────────────────────

  GameState copyWith({
    Puzzle? puzzle,
    List<String>? remainingWords,
    List<String>? selectedWords,
    List<PuzzleGroup>? revealedGroups,
    int? mistakeCount,
    GamePhase? phase,
    bool? shouldShake,
    bool? isOneAway,
    List<PuzzleGroup>? solveSequence,
  }) {
    return GameState(
      puzzle: puzzle ?? this.puzzle,
      remainingWords: remainingWords ?? this.remainingWords,
      selectedWords: selectedWords ?? this.selectedWords,
      revealedGroups: revealedGroups ?? this.revealedGroups,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      phase: phase ?? this.phase,
      shouldShake: shouldShake ?? this.shouldShake,
      isOneAway: isOneAway ?? this.isOneAway,
      solveSequence: solveSequence ?? this.solveSequence,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GameResultData  (passed to ResultScreen via go_router extra)
// ─────────────────────────────────────────────────────────────────────────────

class GameResultData {
  const GameResultData({
    required this.puzzle,
    required this.won,
    required this.solveSequence,
    required this.mistakeCount,
    required this.gameSource,
    this.packName,
  });

  final Puzzle puzzle;
  final bool won;

  /// Groups in the order they were solved (may be partial on failure).
  final List<PuzzleGroup> solveSequence;
  final int mistakeCount;

  /// Whether this game came from the daily challenge or a practice pack.
  final GameSource gameSource;

  /// The pack name (e.g. `'movies'`). Non-null when [gameSource] is [GameSource.pack].
  final String? packName;
}

// ─────────────────────────────────────────────────────────────────────────────
// GameNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Owns the full game state machine.
///
/// Lifecycle:
///   [loadPuzzle] → tiles appear
///   [toggleTile] → selection changes
///   [submitGuess] → correct (reveal) or wrong (shake + mistake)
///   [clearShake] → called by UI after shake animation completes
///
/// When [GamePhase.solved] or [GamePhase.failed] is reached, the GameScreen
/// reads [buildResult] and navigates to ResultScreen.
@Riverpod(keepAlive: true)
class GameNotifier extends _$GameNotifier {
  @override
  GameState build() => const GameState();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Initialises a new game with [puzzle]. Shuffles the word order.
  void loadPuzzle(Puzzle puzzle) {
    final words = puzzle.groups.expand((g) => g.words).toList()..shuffle();
    state = GameState(
      puzzle: puzzle,
      remainingWords: words,
      phase: GamePhase.idle,
    );
  }

  /// Selects or deselects [word]. No-op during shake or terminal phases.
  void toggleTile(String word) {
    final s = state;
    if (s.phase == GamePhase.solved || s.phase == GamePhase.failed) return;
    if (s.shouldShake) return;

    final selected = List<String>.from(s.selectedWords);
    if (selected.contains(word)) {
      selected.remove(word);
    } else if (selected.length < 4) {
      selected.add(word);
    }

    state = s.copyWith(
      selectedWords: selected,
      phase: selected.isEmpty ? GamePhase.idle : GamePhase.selecting,
      isOneAway: false,
    );
  }

  /// Evaluates the current 4-tile selection against all puzzle groups.
  ///
  /// Correct → reveals the group, removes tiles, advances phase.
  /// Wrong   → increments mistake counter, sets [shouldShake].
  void submitGuess() {
    final s = state;
    if (!s.canSubmit) return;
    if (s.puzzle == null) return;

    final selected = Set<String>.from(s.selectedWords);

    // Check every group for an exact set match
    PuzzleGroup? hit;
    for (final group in s.puzzle!.groups) {
      final groupWords = Set<String>.from(group.words);
      if (groupWords.length == selected.length &&
          groupWords.containsAll(selected)) {
        hit = group;
        break;
      }
    }

    if (hit != null) {
      _handleCorrect(s, hit);
    } else {
      _handleWrong(s, selected);
    }
  }

  /// Called by the UI after the shake animation completes.
  ///
  /// Clears [shouldShake] and deselects tiles (unless the game just ended).
  void clearShake() {
    if (!state.shouldShake) return;
    final s = state;
    state = s.copyWith(
      shouldShake: false,
      selectedWords: s.phase == GamePhase.failed ? s.selectedWords : const [],
      isOneAway: false,
    );
  }

  /// Resets notifier to initial state (used when returning home).
  void reset() => state = const GameState();

  /// Snapshots game outcome for navigation to ResultScreen.
  ///
  /// If [gameSource] is [GameSource.pack] and the player won, automatically
  /// marks the puzzle as played in [PackRepository] (fire-and-forget).
  GameResultData buildResult({
    required GameSource gameSource,
    String? packName,
  }) {
    final s = state;
    final won = s.phase == GamePhase.solved;

    final result = GameResultData(
      puzzle: s.puzzle!,
      won: won,
      solveSequence: s.solveSequence,
      mistakeCount: s.mistakeCount,
      gameSource: gameSource,
      packName: packName,
    );

    // Auto-mark the pack puzzle as played when the player wins.
    if (gameSource == GameSource.pack && won && packName != null) {
      ref
          .read(packRepositoryProvider)
          .markPlayed(packName, s.puzzle!.id)
          .then((_) => ref.invalidate(packCompletedProvider(packName)))
          .catchError(
            (Object e) => debugPrint('[PackRepo] markPlayed error: $e'),
          );
    }

    return result;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _handleCorrect(GameState s, PuzzleGroup hit) {
    final selected = Set<String>.from(s.selectedWords);
    final newRevealed = [...s.revealedGroups, hit];
    final newRemaining = s.remainingWords
        .where((w) => !selected.contains(w))
        .toList();
    final newSeq = [...s.solveSequence, hit];
    final solved = newRevealed.length == 4;

    state = s.copyWith(
      revealedGroups: newRevealed,
      remainingWords: newRemaining,
      selectedWords: const [],
      solveSequence: newSeq,
      phase: solved ? GamePhase.solved : GamePhase.idle,
      shouldShake: false,
      isOneAway: false,
    );
  }

  void _handleWrong(GameState s, Set<String> selected) {
    final newMistakes = s.mistakeCount + 1;

    // "One away" detection: 3 of 4 selected belong to an unrevealed group
    bool oneAway = false;
    for (final group in s.puzzle!.groups) {
      if (!s.revealedGroups.contains(group)) {
        if (selected.intersection(Set<String>.from(group.words)).length == 3) {
          oneAway = true;
          break;
        }
      }
    }

    state = s.copyWith(
      mistakeCount: newMistakes,
      shouldShake: true,
      isOneAway: oneAway,
      phase: newMistakes >= 4 ? GamePhase.failed : GamePhase.selecting,
    );
  }
}
