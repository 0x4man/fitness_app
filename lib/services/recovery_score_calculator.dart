import '../models/dynamic_workout_models.dart';

/// Calculates a 0-100 Recovery Score from a day's health inputs.
///
/// Weights are tunable constants below. When ready to move to ML, keep this
/// class as the cold-start fallback and swap a learned model in behind the
/// same `calculate()` signature.
class RecoveryScoreCalculator {
  static const double _sleepWeight = 0.30;
  static const double _energyWeight = 0.20;
  static const double _stressWeight = 0.20;
  static const double _sorenessWeight = 0.20;
  static const double _activityWeight = 0.10;
  static const double _hrvWeight = 0.15; // applied on top when available

  RecoveryScore calculate({
    required DailyHealthInput input,
    required List<String> todaysFocusMuscleGroups,
    double? baselineHrv,
  }) {
    final breakdown = <String, double>{};

    // Sleep: ideal ~8h at quality >= 7.
    final sleepDurationScore =
        _scoreRange(input.sleepHours, ideal: 8.0, tolerance: 1.5);
    final sleepQualityScore = input.sleepQuality / 10.0;
    final sleepScore = sleepDurationScore * 0.6 + sleepQualityScore * 0.4;
    breakdown['sleep'] = (sleepScore * 100) * _sleepWeight;

    // Energy (self-reported).
    final energyScore = input.energyLevel / 10.0;
    breakdown['energy'] = (energyScore * 100) * _energyWeight;

    // Stress (inverse — high stress hurts recovery).
    final stressScore = 1.0 - (input.stressLevel / 10.0);
    breakdown['stress'] = (stressScore * 100) * _stressWeight;

    // Soreness, weighted toward today's target muscles.
    final generalSoreness = input.averageSoreness / 10.0;
    final focusSorenessValues =
        todaysFocusMuscleGroups.map((g) => input.sorenessFor(g)).toList();
    final focusSoreness = focusSorenessValues.isEmpty
        ? generalSoreness
        : (focusSorenessValues.reduce((a, b) => a + b) /
                focusSorenessValues.length) /
            10.0;
    final combinedSorenessScore =
        1.0 - (generalSoreness * 0.4 + focusSoreness * 0.6);
    breakdown['soreness'] = (combinedSorenessScore * 100) * _sorenessWeight;

    // Activity load — very high step counts can mean accumulated fatigue.
    final activityScore = _scoreRange(input.steps.toDouble(),
        ideal: 7000, tolerance: 5000, penalizeAboveMore: true);
    breakdown['activity'] = (activityScore * 100) * _activityWeight;

    double coreTotal = breakdown.values.fold(0.0, (a, b) => a + b);

    // Optional HRV bonus.
    final hrv = input.wearable?.heartRateVariabilityMs;
    if (hrv != null && baselineHrv != null && baselineHrv > 0) {
      final ratio = (hrv / baselineHrv).clamp(0.5, 1.3);
      final hrvScore = ((ratio - 0.5) / 0.8).clamp(0.0, 1.0);
      final hrvContribution = ((hrvScore * 100) * _hrvWeight).toDouble();
      breakdown['hrv'] = hrvContribution;
      coreTotal = coreTotal * (1.0 - _hrvWeight);
      coreTotal += hrvContribution;
    }

    final finalScore = coreTotal.clamp(0.0, 100.0).toDouble();

    return RecoveryScore(
      score: finalScore,
      readiness: ReadinessLevelX.fromScore(finalScore),
      factorBreakdown: breakdown,
    );
  }

  double _scoreRange(
    double value, {
    required double ideal,
    required double tolerance,
    bool penalizeAboveMore = false,
  }) {
    final diff = value - ideal;
    final effectiveTolerance =
        (penalizeAboveMore && diff > 0) ? tolerance / 2 : tolerance;
    final normalized = 1.0 - (diff.abs() / effectiveTolerance);
    return normalized.clamp(0.0, 1.0).toDouble();
  }
}
