import 'package:json_annotation/json_annotation.dart';

part 'puzzle.g.dart';

/// A single group of 4 words sharing a common category.
@JsonSerializable()
class PuzzleGroup {
  final String id;
  final String category;
  final List<String> words;

  /// 1 = easiest (green), 2 = blue, 3 = yellow, 4 = hardest (red)
  final int difficulty;

  const PuzzleGroup({
    required this.id,
    required this.category,
    required this.words,
    required this.difficulty,
  });

  factory PuzzleGroup.fromJson(Map<String, dynamic> json) =>
      _$PuzzleGroupFromJson(json);

  Map<String, dynamic> toJson() => _$PuzzleGroupToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A daily puzzle containing exactly 4 [PuzzleGroup]s (16 words total).
@JsonSerializable(explicitToJson: true)
class Puzzle {
  final String id;

  /// Format: "yyyy-MM-dd"
  final String date;
  final List<PuzzleGroup> groups;

  const Puzzle({
    required this.id,
    required this.date,
    required this.groups,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) => _$PuzzleFromJson(json);

  Map<String, dynamic> toJson() => _$PuzzleToJson(this);
}
