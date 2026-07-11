import '../models/dynamic_workout_models.dart';
import '../models/user_profile.dart';
import '../models/workout_log.dart';

class EngineDecision {
  final ModificationType type;
  final String reason;
  final String? muscleGroup;
  final Map<String, dynamic> params;

  const EngineDecision({
    required this.type,
    required this.reason,
    this.muscleGroup,
    this.params = const {},
  });
}

/// Rule-based decision engine. Each rule inspects state independently and
/// may emit zero or more decisions — add a new rule method, register it in
/// `decide()`, done. To move to ML later, replace the body of `decide()`
/// with a call to a classifier that returns the same List<EngineDecision>;
/// every downstream component (modifier, explainability, UI) is unaffected.
class WorkoutDecisionEngine {
  List<EngineDecision> decide({
    required UserProfile profile,
    required DailyHealthInput input,
    required RecoveryScore recovery,
    required WorkoutPlan basePlan,

    /// Most-recent-first workout history, e.g. from
    /// `WorkoutLogService.getHistory()`.
    required List<WorkoutLog> recentLogs,
  }) {
    final decisions = <EngineDecision>[];

    _ruleLowRecovery(decisions, recovery);
    _ruleHighSorenessOnFocusMuscle(decisions, input, basePlan);
    _rulePoorSleepPlusHighStress(decisions, input);
    _ruleLimitedTime(decisions, input, basePlan);
    _ruleInjurySafety(decisions, profile, basePlan);
    _ruleProgressiveOverload(decisions, profile, recovery, recentLogs);
    _ruleMissedSessions(decisions, profile, recentLogs);

    if (decisions.isEmpty) {
      decisions.add(const EngineDecision(
        type: ModificationType.noChange,
        reason:
            'All signals are within normal range — today\'s plan proceeds as scheduled.',
      ));
    }
    return decisions;
  }

  void _ruleLowRecovery(
      List<EngineDecision> decisions, RecoveryScore recovery) {
    if (recovery.score < 40) {
      decisions.add(EngineDecision(
        type: ModificationType.reduceIntensity,
        reason:
            'Recovery score is ${recovery.score.round()}/100 (Poor). Intensity is reduced by 30% and volume trimmed to keep today productive without digging a deeper fatigue hole.',
        params: const {'intensityFactor': 0.7, 'volumeFactor': 0.7},
      ));
    } else if (recovery.score < 65) {
      decisions.add(EngineDecision(
        type: ModificationType.reduceVolume,
        reason:
            'Recovery score is ${recovery.score.round()}/100 (Moderate). Volume is trimmed by 15% while keeping intensity close to plan, so quality stays high on fewer total reps.',
        params: const {'intensityFactor': 0.9, 'volumeFactor': 0.85},
      ));
    }
  }

  void _ruleHighSorenessOnFocusMuscle(
    List<EngineDecision> decisions,
    DailyHealthInput input,
    WorkoutPlan basePlan,
  ) {
    for (final group in basePlan.focusMuscleGroups) {
      final soreness = input.sorenessFor(group);
      if (soreness >= 7) {
        decisions.add(EngineDecision(
          type: ModificationType.swapMuscleGroup,
          muscleGroup: group,
          reason:
              '$group soreness is $soreness/10 — high enough to risk poor form and slower recovery if trained today. Swapping today\'s focus to a fresher muscle group and moving $group to a later day.',
        ));
      }
    }
  }

  void _rulePoorSleepPlusHighStress(
      List<EngineDecision> decisions, DailyHealthInput input) {
    final poorSleep = input.sleepHours < 5.5 || input.sleepQuality <= 3;
    final highStress = input.stressLevel >= 8;
    if (poorSleep && highStress) {
      decisions.add(EngineDecision(
        type: ModificationType.addRecoveryOrMobilitySession,
        reason:
            'Sleep (${input.sleepHours.toStringAsFixed(1)}h, quality ${input.sleepQuality}/10) and stress (${input.stressLevel}/10) are both in the red zone. Training hard here has poor return and elevated injury risk, so today becomes a mobility and recovery session instead.',
      ));
    }
  }

  void _ruleLimitedTime(
    List<EngineDecision> decisions,
    DailyHealthInput input,
    WorkoutPlan basePlan,
  ) {
    final planned = basePlan.estimatedDurationMinutes;
    if (input.availableTimeMinutes > 0 &&
        input.availableTimeMinutes < planned * 0.75) {
      decisions.add(EngineDecision(
        type: ModificationType.compressWorkout,
        reason:
            'Only ${input.availableTimeMinutes} minutes available vs. the planned ${planned.round()}. The session is compressed by trimming accessory/isolation work and rest time, while keeping the primary compound lifts intact.',
        params: {'targetMinutes': input.availableTimeMinutes},
      ));
    }
  }

  void _ruleInjurySafety(
    List<EngineDecision> decisions,
    UserProfile profile,
    WorkoutPlan basePlan,
  ) {
    for (final group in basePlan.focusMuscleGroups) {
      if (profile.hasInjuryAffecting(group)) {
        decisions.add(EngineDecision(
          type: ModificationType.swapMuscleGroup,
          muscleGroup: group,
          reason:
              'Your profile lists an injury affecting $group. As a safety precaution, today\'s $group work is replaced with an injury-safe alternative focus.',
        ));
      }
    }
  }

  /// Consistent completion + high recovery -> nudge load up. WorkoutLog
  /// has no RPE field, so "manageable effort" is inferred from consistent
  /// completion (sessions logged close to schedule) rather than RPE.
  void _ruleProgressiveOverload(
    List<EngineDecision> decisions,
    UserProfile profile,
    RecoveryScore recovery,
    List<WorkoutLog> recentLogs,
  ) {
    if (recovery.score < 80) return;

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: 14));
    final sessionsInWindow =
        recentLogs.where((l) => l.date.isAfter(windowStart)).length;
    final expected = (profile.workoutFrequencyPerWeek * 2); // 2 weeks

    if (sessionsInWindow >= expected) {
      decisions.add(const EngineDecision(
        type: ModificationType.progressiveOverload,
        reason:
            'Training has been consistent over the last two weeks and recovery is excellent today. Load is nudged up (+5% intensity) to keep driving adaptation.',
        params: {'intensityFactor': 1.05},
      ));
    }
  }

  /// Repeated missed sessions -> lighten today and flag for reschedule.
  /// Since WorkoutLog only records completed workouts, "missed" is
  /// estimated by comparing actual logs against the expected count over a
  /// trailing 14-day window, from profile.workoutFrequencyPerWeek.
  void _ruleMissedSessions(
    List<EngineDecision> decisions,
    UserProfile profile,
    List<WorkoutLog> recentLogs,
  ) {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: 14));
    final actual = recentLogs.where((l) => l.date.isAfter(windowStart)).length;
    final expected = profile.workoutFrequencyPerWeek * 2;
    if (expected == 0) return;

    if (actual <= expected * 0.5) {
      decisions.add(EngineDecision(
        type: ModificationType.rescheduleTrainingDay,
        reason:
            'Only $actual of the ~$expected sessions expected over the last two weeks were completed. Rather than stacking a hard session on an inconsistent stretch, today shifts to a lighter, higher-adherence session and the weekly schedule should be rebalanced.',
      ));
    }
  }
}
