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
  static const String _keyShield = 'streak_shield_active';

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

  /// Whether a streak shield is currently active.
  bool hasShield() => (_box.get(_keyShield) as bool?) ?? false;

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

  /// Activates a streak shield to protect against one missed day.
  Future<void> activateShield() async {
    if (hasShield()) {
      return; // ← prevent stacking
    }
    await _box.put(_keyShield, true);
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

    final yesterday = _dateStr(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final current = getStreak();

    int newStreak;
    if (lastPlayed == yesterday) {
      // Normal continuous streak
      newStreak = current + 1;
    } else {
      // Missed at least one day
      if (hasShield() && current > 0) {
        // Shield saves the existing streak, plus today's win
        newStreak = current + 1;
        await _box.put(_keyShield, false); // consume shield
      } else {
        // Streak broken, start fresh
        newStreak = 1;
      }
    }

    await _box.put(_keyStreak, newStreak);
    await _box.put(_keyLastPlayed, today);
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
