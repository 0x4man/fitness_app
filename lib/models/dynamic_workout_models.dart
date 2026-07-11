// Dynamic Workout Engine models — built directly on your existing
// lib/models/exercise.dart (Exercise) and lib/models/workout_log.dart
// (WorkoutLog), rather than a parallel catalog. Muscle groups and
// equipment stay as the same free-text strings your Exercise model
// already uses ("Chest", "Legs", "Full Body", "Bodyweight", ...) so
// there's no enum-to-string translation layer to maintain.

import 'exercise.dart';

// ---------------------------------------------------------------------------
// Readiness & modification enums
// ---------------------------------------------------------------------------

enum ReadinessLevel { excellent, good, moderate, poor }

extension ReadinessLevelX on ReadinessLevel {
  static ReadinessLevel fromScore(double score) {
    if (score >= 85) return ReadinessLevel.excellent;
    if (score >= 65) return ReadinessLevel.good;
    if (score >= 40) return ReadinessLevel.moderate;
    return ReadinessLevel.poor;
  }

  String get label {
    switch (this) {
      case ReadinessLevel.excellent:
        return 'Excellent';
      case ReadinessLevel.good:
        return 'Good';
      case ReadinessLevel.moderate:
        return 'Moderate';
      case ReadinessLevel.poor:
        return 'Poor';
    }
  }
}

enum ModificationType {
  reduceIntensity,
  reduceVolume,
  swapMuscleGroup,
  compressWorkout,
  addRecoveryOrMobilitySession,
  progressiveOverload,
  rescheduleTrainingDay,
  noChange,
}

// ---------------------------------------------------------------------------
// Daily inputs
// ---------------------------------------------------------------------------

class WearableData {
  final double? restingHeartRateBpm;
  final double? heartRateVariabilityMs;

  const WearableData({this.restingHeartRateBpm, this.heartRateVariabilityMs});

  Map<String, dynamic> toMap() => {
        'restingHeartRateBpm': restingHeartRateBpm,
        'heartRateVariabilityMs': heartRateVariabilityMs,
      };

  factory WearableData.fromMap(Map<String, dynamic> map) => WearableData(
        restingHeartRateBpm: (map['restingHeartRateBpm'] as num?)?.toDouble(),
        heartRateVariabilityMs:
            (map['heartRateVariabilityMs'] as num?)?.toDouble(),
      );
}

class DailyHealthInput {
  final DateTime date;

  final double sleepHours;
  final int sleepQuality; // 1-10
  final int energyLevel; // 1-10
  final int stressLevel; // 1-10
  final String mood;

  /// Keyed by the same muscle-group strings as Exercise.muscleGroup
  /// (e.g. "Legs", "Chest"). 0 (none) - 10 (very sore). Missing = 0.
  final Map<String, int> soreness;

  final int steps;
  final int caloriesConsumed;
  final double proteinGrams;
  final double waterMl;

  final int availableTimeMinutes;
  final WearableData? wearable;

  const DailyHealthInput({
    required this.date,
    required this.sleepHours,
    required this.sleepQuality,
    required this.energyLevel,
    required this.stressLevel,
    required this.mood,
    this.soreness = const {},
    required this.steps,
    required this.caloriesConsumed,
    required this.proteinGrams,
    required this.waterMl,
    required this.availableTimeMinutes,
    this.wearable,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'energyLevel': energyLevel,
        'stressLevel': stressLevel,
        'mood': mood,
        'soreness': soreness,
        'steps': steps,
        'caloriesConsumed': caloriesConsumed,
        'proteinGrams': proteinGrams,
        'waterMl': waterMl,
        'availableTimeMinutes': availableTimeMinutes,
        'wearable': wearable?.toMap(),
      };

  factory DailyHealthInput.fromMap(Map<String, dynamic> map) {
    return DailyHealthInput(
      date: DateTime.parse(map['date']),
      sleepHours: (map['sleepHours'] ?? 0).toDouble(),
      sleepQuality: (map['sleepQuality'] ?? 5) as int,
      energyLevel: (map['energyLevel'] ?? 5) as int,
      stressLevel: (map['stressLevel'] ?? 5) as int,
      mood: map['mood'] ?? '',
      soreness: Map<String, int>.from(map['soreness'] ?? {}),
      steps: (map['steps'] ?? 0) as int,
      caloriesConsumed: (map['caloriesConsumed'] ?? 0) as int,
      proteinGrams: (map['proteinGrams'] ?? 0).toDouble(),
      waterMl: (map['waterMl'] ?? 0).toDouble(),
      availableTimeMinutes: (map['availableTimeMinutes'] ?? 45) as int,
      wearable: map['wearable'] != null
          ? WearableData.fromMap(Map<String, dynamic>.from(map['wearable']))
          : null,
    );
  }

  int sorenessFor(String muscleGroup) => soreness[muscleGroup] ?? 0;

  double get averageSoreness {
    if (soreness.isEmpty) return 0;
    final values = soreness.values;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

// ---------------------------------------------------------------------------
// Today's plan — wraps catalog Exercises with today's prescribed
// sets/reps/rest/intensity, so the catalog Exercise itself is never mutated.
// ---------------------------------------------------------------------------

const List<String> _compoundKeywords = [
  'squat', 'deadlift', 'bench', 'press', 'row', 'pull-up', 'pullup',
  'chin-up', 'lunge', 'clean', 'snatch', 'thruster',
];

class PlannedExerciseItem {
  final Exercise exercise;
  final int sets;
  final int reps;
  final int restSeconds;
  /// 0.0-1.0, roughly %1RM or RPE/10. Scales load without changing the
  /// exercise itself.
  final double intensity;

  const PlannedExerciseItem({
    required this.exercise,
    required this.sets,
    required this.reps,
    this.restSeconds = 60,
    this.intensity = 0.7,
  });

  factory PlannedExerciseItem.fromCatalog(Exercise exercise, {int restSeconds = 60, double intensity = 0.7}) {
    return PlannedExerciseItem(
      exercise: exercise,
      sets: exercise.defaultSets,
      reps: exercise.defaultReps,
      restSeconds: restSeconds,
      intensity: intensity,
    );
  }

  /// Inferred from the exercise name — your Exercise model doesn't have an
  /// isCompound flag yet. Add one to the catalog for a more reliable signal.
  bool get isCompound => _compoundKeywords
      .any((k) => exercise.name.toLowerCase().contains(k));

  String get muscleGroup => exercise.muscleGroup;

  double get estimatedMinutes {
    final workSeconds = sets * (reps * 3);
    final restTotal = sets * restSeconds;
    return (workSeconds + restTotal) / 60.0;
  }

  PlannedExerciseItem copyWith({
    Exercise? exercise,
    int? sets,
    int? reps,
    int? restSeconds,
    double? intensity,
  }) {
    return PlannedExerciseItem(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      intensity: intensity ?? this.intensity,
    );
  }
}

class WorkoutPlan {
  final String id;
  final String dayLabel;
  final List<String> focusMuscleGroups;
  final List<PlannedExerciseItem> exercises;

  const WorkoutPlan({
    required this.id,
    required this.dayLabel,
    required this.focusMuscleGroups,
    required this.exercises,
  });

  double get estimatedDurationMinutes =>
      exercises.fold(0.0, (sum, e) => sum + e.estimatedMinutes) + 5;

  WorkoutPlan copyWith({
    String? id,
    String? dayLabel,
    List<String>? focusMuscleGroups,
    List<PlannedExerciseItem>? exercises,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      dayLabel: dayLabel ?? this.dayLabel,
      focusMuscleGroups: focusMuscleGroups ?? this.focusMuscleGroups,
      exercises: exercises ?? this.exercises,
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery score
// ---------------------------------------------------------------------------

class RecoveryScore {
  final double score; // 0-100
  final ReadinessLevel readiness;
  final Map<String, double> factorBreakdown;

  const RecoveryScore({
    required this.score,
    required this.readiness,
    required this.factorBreakdown,
  });
}

// ---------------------------------------------------------------------------
// Modifications & result
// ---------------------------------------------------------------------------

class Modification {
  final ModificationType type;
  final String summary;
  final String reason;
  final String? affectedMuscleGroup;

  const Modification({
    required this.type,
    required this.summary,
    required this.reason,
    this.affectedMuscleGroup,
  });
}

class DynamicWorkoutResult {
  final RecoveryScore recoveryScore;
  final WorkoutPlan todaysWorkout;
  final List<Modification> modifications;
  final double estimatedDurationMinutes;
  final List<String> recoveryRecommendations;

  const DynamicWorkoutResult({
    required this.recoveryScore,
    required this.todaysWorkout,
    required this.modifications,
    required this.estimatedDurationMinutes,
    required this.recoveryRecommendations,
  });

  bool get wasModified =>
      modifications.any((m) => m.type != ModificationType.noChange);
}