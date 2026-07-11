import '../models/dynamic_workout_models.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../models/workout_log.dart';
import 'recovery_score_calculator.dart';
import 'workout_decision_engine.dart';
import 'workout_modifier.dart';

/// Public entry point for VIORA's Dynamic Workout Engine.
///
/// Pipeline: UserProfile + DailyHealthInput
///   -> RecoveryScoreCalculator   (0-100 score + factor breakdown)
///   -> WorkoutDecisionEngine     (rule-based decisions, using WorkoutLog history)
///   -> WorkoutModifier           (applies decisions to the base plan, using the exercise catalog)
///   -> recovery recommendations  (explainability-adjacent, user-facing tips)
///
/// Pure logic, no Firebase/UI dependencies — easy to unit test and reuse
/// from a provider, a cloud function, or a background job.
class DynamicWorkoutEngine {
  final RecoveryScoreCalculator _recoveryCalculator;
  final WorkoutDecisionEngine _decisionEngine;
  final WorkoutModifier _modifier;

  DynamicWorkoutEngine({
    RecoveryScoreCalculator? recoveryCalculator,
    WorkoutDecisionEngine? decisionEngine,
    WorkoutModifier? modifier,
  })  : _recoveryCalculator = recoveryCalculator ?? RecoveryScoreCalculator(),
        _decisionEngine = decisionEngine ?? WorkoutDecisionEngine(),
        _modifier = modifier ?? WorkoutModifier();

  DynamicWorkoutResult generateTodaysWorkout({
    required UserProfile profile,
    required DailyHealthInput dailyInput,
    required WorkoutPlan basePlan,
    /// Most-recent-first, e.g. from `WorkoutLogService.getHistory()`.
    List<WorkoutLog> recentLogs = const [],
    /// The flat catalog from `ExerciseService.getExercises()`. Filtering
    /// by muscle group / equipment / difficulty happens inside the
    /// modifier — pass the whole list.
    List<Exercise> exerciseCatalog = const [],
    double? baselineHrv,
  }) {
    final recoveryScore = _recoveryCalculator.calculate(
      input: dailyInput,
      todaysFocusMuscleGroups: basePlan.focusMuscleGroups,
      baselineHrv: baselineHrv,
    );

    final decisions = _decisionEngine.decide(
      profile: profile,
      input: dailyInput,
      recovery: recoveryScore,
      basePlan: basePlan,
      recentLogs: recentLogs,
    );

    final result = _modifier.apply(
      basePlan: basePlan,
      decisions: decisions,
      profile: profile,
      exerciseCatalog: exerciseCatalog,
    );

    final recommendations = _buildRecoveryRecommendations(
      dailyInput: dailyInput,
      recoveryScore: recoveryScore,
      profile: profile,
    );

    return DynamicWorkoutResult(
      recoveryScore: recoveryScore,
      todaysWorkout: result.plan,
      modifications: result.modifications,
      estimatedDurationMinutes: result.plan.estimatedDurationMinutes,
      recoveryRecommendations: recommendations,
    );
  }

  List<String> _buildRecoveryRecommendations({
    required DailyHealthInput dailyInput,
    required RecoveryScore recoveryScore,
    required UserProfile profile,
  }) {
    final tips = <String>[];

    if (dailyInput.sleepHours < 7) {
      tips.add(
          'Aim for at least 7 hours of sleep tonight — you got ${dailyInput.sleepHours.toStringAsFixed(1)}h, which is the single biggest lever on tomorrow\'s recovery score.');
    }
    if (dailyInput.stressLevel >= 7) {
      tips.add(
          'Stress is elevated (${dailyInput.stressLevel}/10). A short walk, breathing exercise, or even 10 minutes of downtime can measurably speed recovery.');
    }
    if (dailyInput.waterMl < 2000) {
      tips.add(
          'Hydration looks low today — try to get closer to 2-3L, especially before and after training.');
    }
    final proteinTargetGrams = profile.weightKg * 1.6; // g/kg, general guideline
    if (dailyInput.proteinGrams < proteinTargetGrams) {
      tips.add(
          'Protein intake (${dailyInput.proteinGrams.round()}g) is below the roughly ${proteinTargetGrams.round()}g/day that supports recovery at your bodyweight.');
    }
    if (dailyInput.averageSoreness >= 6) {
      tips.add(
          'General soreness is high — consider a short mobility or foam-rolling session on your off hours today.');
    }
    if (recoveryScore.score >= 85) {
      tips.add(
          'Recovery is excellent — this is a good day to push intensity if you\'re chasing a PR.');
    }
    if (tips.isEmpty) {
      tips.add('Everything looks balanced today — keep doing what you\'re doing.');
    }
    return tips;
  }
}