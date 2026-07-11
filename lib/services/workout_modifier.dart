import '../models/dynamic_workout_models.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import 'workout_decision_engine.dart';

/// Applies a list of [EngineDecision]s to a base [WorkoutPlan], producing a
/// modified plan plus the human-facing [Modification] list. This class
/// edits a clone of the existing plan — it never builds a workout from
/// scratch, so every change traces back to "what was different from the
/// plan today," which is what makes the explainability layer meaningful.
///
/// Muscle-group swaps pull from [exerciseCatalog] — pass in the full list
/// from `ExerciseService.getExercises()` (it's a flat, unfiltered list, so
/// filtering by muscle group / equipment / difficulty happens here).
class WorkoutModifier {
  ({WorkoutPlan plan, List<Modification> modifications}) apply({
    required WorkoutPlan basePlan,
    required List<EngineDecision> decisions,
    required UserProfile profile,
    List<Exercise> exerciseCatalog = const [],
  }) {
    var plan = basePlan.copyWith(
      exercises: List<PlannedExerciseItem>.from(basePlan.exercises),
    );
    final modifications = <Modification>[];

    for (final decision in decisions) {
      switch (decision.type) {
        case ModificationType.reduceIntensity:
        case ModificationType.reduceVolume:
          plan = _scaleLoad(
            plan,
            intensityFactor:
                (decision.params['intensityFactor'] as double?) ?? 1.0,
            volumeFactor: (decision.params['volumeFactor'] as double?) ?? 1.0,
          );
          modifications.add(Modification(
            type: decision.type,
            summary: decision.type == ModificationType.reduceIntensity
                ? 'Reduced intensity and volume'
                : 'Trimmed training volume',
            reason: decision.reason,
          ));
          break;

        case ModificationType.swapMuscleGroup:
          final group = decision.muscleGroup;
          if (group != null) {
            plan = _swapMuscleGroup(plan, group, profile, exerciseCatalog);
            modifications.add(Modification(
              type: decision.type,
              summary: 'Swapped $group focus',
              reason: decision.reason,
              affectedMuscleGroup: group,
            ));
          }
          break;

        case ModificationType.compressWorkout:
          final targetMinutes =
              (decision.params['targetMinutes'] as int?) ?? 30;
          plan = _compress(plan, targetMinutes);
          modifications.add(Modification(
            type: decision.type,
            summary: 'Compressed to fit $targetMinutes min',
            reason: decision.reason,
          ));
          break;

        case ModificationType.addRecoveryOrMobilitySession:
          plan = _replaceWithRecoverySession(plan, profile, exerciseCatalog);
          modifications.add(Modification(
            type: decision.type,
            summary: 'Switched to recovery / mobility session',
            reason: decision.reason,
          ));
          break;

        case ModificationType.progressiveOverload:
          final factor =
              (decision.params['intensityFactor'] as double?) ?? 1.05;
          plan = _scaleLoad(plan, intensityFactor: factor, volumeFactor: 1.0);
          modifications.add(Modification(
            type: decision.type,
            summary: 'Increased load ~5%',
            reason: decision.reason,
          ));
          break;

        case ModificationType.rescheduleTrainingDay:
          plan = _scaleLoad(plan, intensityFactor: 0.85, volumeFactor: 0.8);
          modifications.add(Modification(
            type: decision.type,
            summary: 'Lightened session, schedule rebalanced',
            reason: decision.reason,
          ));
          break;

        case ModificationType.noChange:
          modifications.add(Modification(
            type: ModificationType.noChange,
            summary: 'No changes',
            reason: decision.reason,
          ));
          break;
      }
    }

    return (plan: plan, modifications: modifications);
  }

  WorkoutPlan _scaleLoad(
    WorkoutPlan plan, {
    required double intensityFactor,
    required double volumeFactor,
  }) {
    final scaled = plan.exercises.map((e) {
      final newSets = (e.sets * volumeFactor).round().clamp(1, e.sets).toInt();
      final newIntensity =
          (e.intensity * intensityFactor).clamp(0.3, 1.0).toDouble();
      return e.copyWith(sets: newSets, intensity: newIntensity);
    }).toList();
    return plan.copyWith(exercises: scaled);
  }

  /// Filters the catalog to exercises the user can actually do: equipment
  /// they have access to (or bodyweight, always available) and difficulty
  /// at or below their experience level.
  List<Exercise> _usableExercises(
    List<Exercise> catalog,
    UserProfile profile, {
    String? muscleGroup,
    String? excludeMuscleGroup,
  }) {
    const difficultyOrder = {'Beginner': 0, 'Intermediate': 1, 'Advanced': 2};
    final userLevel = difficultyOrder[profile.experienceLevel] ?? 0;

    return catalog.where((ex) {
      final equipmentOk = ex.equipment == 'Bodyweight' ||
          profile.availableEquipment.isEmpty ||
          profile.hasEquipment(ex.equipment);
      final difficultyOk = (difficultyOrder[ex.difficulty] ?? 0) <= userLevel;
      final muscleGroupOk =
          muscleGroup == null || ex.muscleGroup == muscleGroup;
      final excludedOk =
          excludeMuscleGroup == null || ex.muscleGroup != excludeMuscleGroup;
      return equipmentOk && difficultyOk && muscleGroupOk && excludedOk;
    }).toList();
  }

  WorkoutPlan _swapMuscleGroup(
    WorkoutPlan plan,
    String soreGroup,
    UserProfile profile,
    List<Exercise> catalog,
  ) {
    final keep =
        plan.exercises.where((e) => e.muscleGroup != soreGroup).toList();

    // Prefer a fresh muscle group not already trained today.
    final alreadyTrained = plan.exercises.map((e) => e.muscleGroup).toSet();
    final candidates =
        _usableExercises(catalog, profile, excludeMuscleGroup: soreGroup)
            .where((ex) => !alreadyTrained.contains(ex.muscleGroup))
            .toList();
    final fallbackCandidates =
        _usableExercises(catalog, profile, excludeMuscleGroup: soreGroup);

    final replacementExercise = candidates.isNotEmpty
        ? candidates.first
        : (fallbackCandidates.isNotEmpty
            ? fallbackCandidates.first
            : Exercise(
                id: 'fallback-mobility',
                name: 'Active Recovery Mobility',
                muscleGroup: 'Full Body',
                equipment: 'Bodyweight',
                difficulty: 'Beginner',
                defaultSets: 1,
                defaultReps: 1,
                instructions: const [],
              ));
    final replacement = PlannedExerciseItem.fromCatalog(replacementExercise);

    final newFocus = plan.focusMuscleGroups
        .map((g) => g == soreGroup ? replacement.muscleGroup : g)
        .toSet()
        .toList();

    return plan.copyWith(
      exercises: [...keep, replacement],
      focusMuscleGroups: newFocus,
    );
  }

  WorkoutPlan _compress(WorkoutPlan plan, int targetMinutes) {
    final sorted = [...plan.exercises]
      ..sort((a, b) => (b.isCompound ? 1 : 0) - (a.isCompound ? 1 : 0));

    final kept = <PlannedExerciseItem>[];
    double runningMinutes = 5; // warm-up baseline
    for (final ex in sorted) {
      final compressedRest = (ex.restSeconds * 0.7).round();
      final compressedEx = ex.copyWith(restSeconds: compressedRest);
      final projected = runningMinutes + compressedEx.estimatedMinutes;
      if (projected <= targetMinutes || ex.isCompound) {
        kept.add(compressedEx);
        runningMinutes = projected;
      }
      // Non-compound exercises that would blow the budget are dropped.
    }
    return plan.copyWith(exercises: kept);
  }

  WorkoutPlan _replaceWithRecoverySession(
    WorkoutPlan plan,
    UserProfile profile,
    List<Exercise> catalog,
  ) {
    final candidates = _usableExercises(catalog, profile,
        muscleGroup: 'Core'); // gentle bodyweight-friendly group
    final mobilityCandidate = candidates.isNotEmpty
        ? candidates.first
        : Exercise(
            id: 'fallback-mobility',
            name: 'Guided Mobility Flow',
            muscleGroup: 'Full Body',
            equipment: 'Bodyweight',
            difficulty: 'Beginner',
            defaultSets: 1,
            defaultReps: 1,
            instructions: const [],
          );

    return plan.copyWith(
      dayLabel: 'Recovery & Mobility',
      focusMuscleGroups: ['Full Body'],
      exercises: [
        PlannedExerciseItem.fromCatalog(mobilityCandidate, intensity: 0.2),
      ],
    );
  }
}
