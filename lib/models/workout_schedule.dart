// A user's weekly training split — "Monday = Push, Tuesday = Rest, ..."
// This is the missing piece the Dynamic Workout Engine needs: something
// that defines what today's plan *would be* before any adaptation happens.

import 'exercise.dart';
import 'dynamic_workout_models.dart';

const List<String> weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Lightweight reference to a catalog Exercise plus the sets/reps prescribed
/// for it on this scheduled day. Deliberately not a full Exercise — only
/// stores what's needed to look the real Exercise back up later, so if the
/// catalog entry's instructions/equipment change, the schedule stays valid.
class ScheduledExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;

  const ScheduledExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
  });

  factory ScheduledExercise.fromExercise(Exercise exercise) {
    return ScheduledExercise(
      exerciseId: exercise.id,
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      sets: exercise.defaultSets,
      reps: exercise.defaultReps,
    );
  }

  ScheduledExercise copyWith({int? sets, int? reps}) {
    return ScheduledExercise(
      exerciseId: exerciseId,
      name: name,
      muscleGroup: muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
    );
  }

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'reps': reps,
      };

  factory ScheduledExercise.fromMap(Map<String, dynamic> map) {
    return ScheduledExercise(
      exerciseId: map['exerciseId'] ?? '',
      name: map['name'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      sets: (map['sets'] ?? 3) as int,
      reps: (map['reps'] ?? 10) as int,
    );
  }
}

class ScheduledDay {
  final String dayOfWeek; // one of weekdayNames
  final bool isRestDay;
  final String dayLabel; // e.g. "Push Day"
  final List<ScheduledExercise> exercises;

  const ScheduledDay({
    required this.dayOfWeek,
    this.isRestDay = false,
    this.dayLabel = '',
    this.exercises = const [],
  });

  factory ScheduledDay.rest(String dayOfWeek) =>
      ScheduledDay(dayOfWeek: dayOfWeek, isRestDay: true, dayLabel: 'Rest Day');

  List<String> get focusMuscleGroups =>
      exercises.map((e) => e.muscleGroup).toSet().toList();

  ScheduledDay copyWith({
    bool? isRestDay,
    String? dayLabel,
    List<ScheduledExercise>? exercises,
  }) {
    return ScheduledDay(
      dayOfWeek: dayOfWeek,
      isRestDay: isRestDay ?? this.isRestDay,
      dayLabel: dayLabel ?? this.dayLabel,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Converts this scheduled day into a WorkoutPlan the engine can adapt,
  /// hydrating each ScheduledExercise against the live catalog. Falls back
  /// to a minimal stand-in Exercise if a saved ID isn't found (e.g. it was
  /// deleted from the catalog since scheduling).
  WorkoutPlan toWorkoutPlan(List<Exercise> catalog) {
    final items = exercises.map((se) {
      final match = catalog.where((e) => e.id == se.exerciseId).toList();
      final exercise = match.isNotEmpty
          ? match.first
          : Exercise(
              id: se.exerciseId,
              name: se.name,
              muscleGroup: se.muscleGroup,
              equipment: 'Bodyweight',
              difficulty: 'Beginner',
              defaultSets: se.sets,
              defaultReps: se.reps,
              instructions: const [],
            );
      return PlannedExerciseItem(
        exercise: exercise,
        sets: se.sets,
        reps: se.reps,
      );
    }).toList();

    return WorkoutPlan(
      id: dayOfWeek,
      dayLabel: dayLabel.isNotEmpty ? dayLabel : dayOfWeek,
      focusMuscleGroups: focusMuscleGroups,
      exercises: items,
    );
  }

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'isRestDay': isRestDay,
        'dayLabel': dayLabel,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory ScheduledDay.fromMap(Map<String, dynamic> map) {
    return ScheduledDay(
      dayOfWeek: map['dayOfWeek'] ?? '',
      isRestDay: map['isRestDay'] ?? false,
      dayLabel: map['dayLabel'] ?? '',
      exercises: (map['exercises'] as List<dynamic>? ?? [])
          .map((e) => ScheduledExercise.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class WorkoutSchedule {
  final Map<String, ScheduledDay> days; // keyed by weekdayNames entries

  const WorkoutSchedule({required this.days});

  factory WorkoutSchedule.empty() => WorkoutSchedule(
        days: {for (final d in weekdayNames) d: ScheduledDay.rest(d)},
      );

  /// [weekday] uses DateTime.weekday convention: 1 = Monday ... 7 = Sunday.
  ScheduledDay forWeekday(int weekday) {
    final name = weekdayNames[(weekday - 1).clamp(0, 6).toInt()];
    return days[name] ?? ScheduledDay.rest(name);
  }

  ScheduledDay forToday() => forWeekday(DateTime.now().weekday);

  WorkoutSchedule updateDay(ScheduledDay day) {
    final updated = Map<String, ScheduledDay>.from(days);
    updated[day.dayOfWeek] = day;
    return WorkoutSchedule(days: updated);
  }

  Map<String, dynamic> toMap() =>
      {'days': days.map((k, v) => MapEntry(k, v.toMap()))};

  factory WorkoutSchedule.fromMap(Map<String, dynamic> map) {
    final rawDays = map['days'] as Map<String, dynamic>? ?? {};
    final days = <String, ScheduledDay>{};
    for (final name in weekdayNames) {
      days[name] = rawDays.containsKey(name)
          ? ScheduledDay.fromMap(Map<String, dynamic>.from(rawDays[name]))
          : ScheduledDay.rest(name);
    }
    return WorkoutSchedule(days: days);
  }
}
