/// Represents a single exercise in the global `exercises` Firestore
/// collection — shared across all users (not per-user data).
class Exercise {
  final String id;
  final String name;
  final String muscleGroup; // Chest, Back, Legs, Shoulders, Arms, Core, Full Body
  final String equipment; // Bodyweight, Dumbbell, Barbell, Machine, etc.
  final String difficulty; // Beginner, Intermediate, Advanced
  final int defaultSets;
  final int defaultReps;
  final List<String> instructions;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.defaultSets,
    required this.defaultReps,
    required this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'instructions': instructions,
    };
  }

  factory Exercise.fromMap(String id, Map<String, dynamic> map) {
    return Exercise(
      id: id,
      name: map['name'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      equipment: map['equipment'] ?? '',
      difficulty: map['difficulty'] ?? 'Beginner',
      defaultSets: (map['defaultSets'] ?? 3) as int,
      defaultReps: (map['defaultReps'] ?? 10) as int,
      instructions: List<String>.from(map['instructions'] ?? []),
    );
  }
}