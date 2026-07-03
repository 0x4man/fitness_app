import 'package:flutter/foundation.dart';
import '../models/exercise.dart';

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
