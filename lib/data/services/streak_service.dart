import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed service for managing the player's daily streak and played puzzles.
///
/// All Hive writes are synchronous (box is pre-opened in [main]).
/// No TypeAdapters needed — only primitives are stored.
class StreakService {
  StreakService._();

  static const String boxName = 'streak_box';
  static const String _keyStreak = 'streakCount';
  static const String _keyLastPlayed = 'lastPlayedDate';
  static const String _keyPlayedIds = 'playedPuzzleIds';

  // Lazy singleton
  static final StreakService instance = StreakService._();

  Box get _box => Hive.box(boxName);

  // ── Reads ────────────────────────────────────────────────────────────────

  /// Current streak length (0 if never played).
  int getStreak() => (_box.get(_keyStreak) as int?) ?? 0;

  /// Date of the last solved game in "yyyy-MM-dd" format, or null.
  String? getLastPlayedDate() => _box.get(_keyLastPlayed) as String?;

  /// Whether [puzzleId] has already been completed.
  bool isPuzzlePlayed(String puzzleId) {
    return _getPlayedIds().contains(puzzleId);
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Records that [puzzleId] was completed.
  ///
  /// If [won] is true the streak is also incremented (consecutive-day logic).
  Future<void> markPuzzlePlayed(String puzzleId, {required bool won}) async {
    final ids = _getPlayedIds();
    if (!ids.contains(puzzleId)) {
      ids.add(puzzleId);
      await _box.put(_keyPlayedIds, ids);
    }
    if (won) await _incrementStreak();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  List<String> _getPlayedIds() {
    final raw = _box.get(_keyPlayedIds);
    if (raw == null) return <String>[];
    return List<String>.from(raw as List);
  }

  Future<void> _incrementStreak() async {
    final today = _dateStr(DateTime.now());
    final lastPlayed = getLastPlayedDate();

    // Idempotent — already counted today
    if (lastPlayed == today) return;

    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final current = getStreak();

    final newStreak = (lastPlayed == yesterday) ? current + 1 : 1;
    await _box.put(_keyStreak, newStreak);
    await _box.put(_keyLastPlayed, today);
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
