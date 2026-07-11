import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/dynamic_workout_models.dart';

/// A single set being tracked for an exercise in the current
/// in-progress workout session (before it's saved as a WorkoutLog).
class TrackedSet {
  int reps;
  double weight;
  bool completed;

  TrackedSet({required this.reps, this.weight = 0, this.completed = false});
}

/// An exercise added to the current session, with its editable sets.
class TrackedExercise {
  final Exercise exercise;
  final List<TrackedSet> sets;

  TrackedExercise({required this.exercise, required this.sets});
}

/// Holds the "Today's Workout" in-progress session in memory —
/// exercises added from the Workout Library, with per-set reps/weight
/// tracking, until the user finishes (saves) or discards the session.
/// Registered as a ChangeNotifierProvider above MaterialApp in
/// main.dart so any screen can read/update it.
class WorkoutSessionProvider extends ChangeNotifier {
  final List<TrackedExercise> _exercises = [];

  List<TrackedExercise> get exercises => List.unmodifiable(_exercises);
  bool get isEmpty => _exercises.isEmpty;
  int get exerciseCount => _exercises.length;

  bool containsExercise(String exerciseId) {
    return _exercises.any((e) => e.exercise.id == exerciseId);
  }

  void addExercise(Exercise exercise) {
    if (containsExercise(exercise.id)) return;
    _exercises.add(
      TrackedExercise(
        exercise: exercise,
        sets: List.generate(
          exercise.defaultSets,
          (_) => TrackedSet(reps: exercise.defaultReps),
        ),
      ),
    );
    notifyListeners();
  }

  /// Loads the session straight from a Dynamic Workout Engine result,
  /// replacing whatever's currently in progress. Unlike addExercise()
  /// (which uses the catalog's default sets/reps), this uses each
  /// PlannedExerciseItem's sets/reps exactly as the engine set them —
  /// so a recovery-trimmed session shows up trimmed here too, not the
  /// untouched library defaults.
  void loadFromPlan(WorkoutPlan plan) {
    _exercises
      ..clear()
      ..addAll(plan.exercises.map((item) => TrackedExercise(
            exercise: item.exercise,
            sets: List.generate(
              item.sets,
              (_) => TrackedSet(reps: item.reps),
            ),
          )));
    notifyListeners();
  }

  void removeExercise(int index) {
    _exercises.removeAt(index);
    notifyListeners();
  }

  void addSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex].exercise;
    _exercises[exerciseIndex].sets.add(TrackedSet(reps: exercise.defaultReps));
    notifyListeners();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    _exercises[exerciseIndex].sets.removeAt(setIndex);
    notifyListeners();
  }

  void toggleSetComplete(int exerciseIndex, int setIndex) {
    final set = _exercises[exerciseIndex].sets[setIndex];
    set.completed = !set.completed;
    notifyListeners();
  }

  void updateReps(int exerciseIndex, int setIndex, int reps) {
    _exercises[exerciseIndex].sets[setIndex].reps = reps;
    notifyListeners();
  }

  void updateWeight(int exerciseIndex, int setIndex, double weight) {
    _exercises[exerciseIndex].sets[setIndex].weight = weight;
    notifyListeners();
  }

  void clear() {
    _exercises.clear();
    notifyListeners();
  }
}
