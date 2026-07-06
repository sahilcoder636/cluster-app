import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/puzzle.dart';

part 'puzzle_repository.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository (plain class — not a provider itself)
// ─────────────────────────────────────────────────────────────────────────────

/// Loads and caches puzzle data from [assets/puzzles.json].
class PuzzleRepository {
  List<Puzzle>? _cache;

  /// Loads all puzzles from the bundled JSON asset.
  Future<List<Puzzle>> loadAll() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/puzzles.json');
    final jsonList = jsonDecode(jsonStr) as List<dynamic>;
    _cache = jsonList
        .map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  /// Returns the puzzle whose [Puzzle.date] matches today's local date,
  /// or `null` if no puzzle is scheduled for today.
  Future<Puzzle?> getTodaysPuzzle() async {
    final puzzles = await loadAll();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      return puzzles.firstWhere((p) => p.date == todayStr);
    } catch (_) {
      return null;
    }
  }

  /// Returns a puzzle by its [id], or `null` if not found.
  Future<Puzzle?> getPuzzleById(String id) async {
    final puzzles = await loadAll();
    try {
      return puzzles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides a singleton [PuzzleRepository] instance.
@Riverpod(keepAlive: true)
PuzzleRepository puzzleRepository(Ref ref) => PuzzleRepository();

/// Async provider that resolves today's puzzle.
/// Returns `null` when no puzzle is found for today's date.
@riverpod
Future<Puzzle?> todaysPuzzle(Ref ref) {
  final repo = ref.watch(puzzleRepositoryProvider);
  return repo.getTodaysPuzzle();
}
