/// A single set within a logged exercise — the actual reps/weight
/// performed, as opposed to Exercise.defaultSets/defaultReps which
/// are just suggestions from the library.
class LoggedSet {
  final int reps;
  final double weight;

  LoggedSet({required this.reps, required this.weight});

  Map<String, dynamic> toMap() => {'reps': reps, 'weight': weight};

  factory LoggedSet.fromMap(Map<String, dynamic> map) {
    return LoggedSet(
      reps: (map['reps'] ?? 0) as int,
      weight: (map['weight'] ?? 0).toDouble(),
    );
  }
}

/// One exercise within a completed workout, with the sets actually
/// performed.
class LoggedExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final List<LoggedSet> sets;

  LoggedExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  factory LoggedExercise.fromMap(Map<String, dynamic> map) {
    return LoggedExercise(
      exerciseId: map['exerciseId'] ?? '',
      name: map['name'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      sets: (map['sets'] as List<dynamic>? ?? [])
          .map((s) => LoggedSet.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

/// A completed workout session, stored at
/// `users/{uid}/workoutLogs/{logId}`. Powers workout history, the
/// Day Streak stat, and Workouts This Week on the Home Dashboard.
class WorkoutLog {
  final String id;
  final DateTime date;
  final List<LoggedExercise> exercises;
  final int durationMinutes;

  WorkoutLog({
    required this.id,
    required this.date,
    required this.exercises,
    required this.durationMinutes,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'durationMinutes': durationMinutes,
      };

  factory WorkoutLog.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutLog(
      id: id,
      date: DateTime.parse(map['date']),
      exercises: (map['exercises'] as List<dynamic>? ?? [])
          .map((e) => LoggedExercise.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      durationMinutes: (map['durationMinutes'] ?? 0) as int,
    );
  }
}
