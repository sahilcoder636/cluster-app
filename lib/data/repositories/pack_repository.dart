import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/puzzle.dart';

/// Plain (non-Riverpod) repository that loads puzzle packs from bundled assets
/// and tracks which puzzles have been played, persisting state in Hive.
class PackRepository {
  static const String _boxName = 'pack_played_box';

  // In-memory cache so each pack JSON is only decoded once per app session.
  final Map<String, List<Puzzle>> _cache = {};

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Loads all [Puzzle]s for the given [packName] from
  /// `assets/packs/<packName>.json`. Results are cached in memory.
  ///
  /// [packName] must be one of: `'movies'`, `'sports'`, `'music'`, `'food'`.
  Future<List<Puzzle>> loadPack(String packName) async {
    if (_cache.containsKey(packName)) return _cache[packName]!;

    final jsonStr = await rootBundle.loadString('assets/packs/$packName.json');
    final jsonList = jsonDecode(jsonStr) as List<dynamic>;
    final puzzles = jsonList
        .map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache[packName] = puzzles;
    return puzzles;
  }

  /// Returns the first [Puzzle] in [packName] whose id is NOT in [playedIds],
  /// or `null` if every puzzle in the pack has been played.
  Future<Puzzle?> getNextUnplayedPuzzle(
    String packName,
    Set<String> playedIds,
  ) async {
    final puzzles = await loadPack(packName);
    try {
      return puzzles.firstWhere((p) => !playedIds.contains(p.id));
    } catch (_) {
      return null;
    }
  }

  // ── Hive-backed played tracking ───────────────────────────────────────────

  /// Returns the set of puzzle ids that have been marked as played for
  /// [packName]. Returns an empty set if nothing has been played yet.
  Future<Set<String>> getPlayedIds(String packName) async {
    final box = Hive.box<dynamic>(_boxName);
    final raw = box.get(packName);
    if (raw == null) return {};
    // Stored as List<dynamic>; cast each element to String.
    return (raw as List<dynamic>).map((e) => e as String).toSet();
  }

  /// Marks [puzzleId] as played for [packName] by appending to the Hive list.
  Future<void> markPlayed(String packName, String puzzleId) async {
    final box = Hive.box<dynamic>(_boxName);
    final existing = await getPlayedIds(packName);
    existing.add(puzzleId);
    await box.put(packName, existing.toList());
  }

  /// Checks if all puzzles in [packName] have been played.
  Future<bool> isPackCompleted(String packName) async {
    final puzzles = await loadPack(packName);
    final playedIds = await getPlayedIds(packName);
    return playedIds.length >= puzzles.length;
  }

  /// Clears the played history for [packName].
  Future<void> resetPack(String packName) async {
    final box = Hive.box<dynamic>(_boxName);
    await box.delete(packName);
  }
}

/// Riverpod provider that exposes a shared [PackRepository] instance.
final packRepositoryProvider = Provider<PackRepository>(
  (ref) => PackRepository(),
);

/// Provider to watch the completion state of a specific pack.
final packCompletedProvider = FutureProvider.family<bool, String>((
  ref,
  packName,
) async {
  final repo = ref.watch(packRepositoryProvider);
  return repo.isPackCompleted(packName);
});
