import 'package:flutter/foundation.dart';

import '../models/dynamic_workout_models.dart';
import '../models/user_profile.dart';
import '../services/dynamic_workout_engine.dart';
import '../services/exercise_service.dart';
import '../services/workout_log_service.dart';

/// Exposes the Dynamic Workout Engine to the widget tree.
///
/// Usage — register alongside your other providers in main.dart:
/// ```dart
/// ChangeNotifierProvider(create: (_) => DynamicWorkoutProvider()),
/// ```
///
/// Then from a screen:
/// ```dart
/// await context.read<DynamicWorkoutProvider>().generateToday(
///   profile: userProfile,
///   dailyInput: todaysHealthInput,
///   basePlan: scheduledPlanForToday,
/// );
/// final result = context.watch<DynamicWorkoutProvider>().result;
/// ```
///
/// Workout history (via WorkoutLogService) and the exercise catalog (via
/// ExerciseService — including its auto-seed on first run) are fetched
/// automatically; you don't need to pass either in yourself.
class DynamicWorkoutProvider extends ChangeNotifier {
  final DynamicWorkoutEngine _engine;
  final WorkoutLogService _logService;
  final ExerciseService _exerciseService;

  DynamicWorkoutProvider({
    DynamicWorkoutEngine? engine,
    WorkoutLogService? logService,
    ExerciseService? exerciseService,
  })  : _engine = engine ?? DynamicWorkoutEngine(),
        _logService = logService ?? WorkoutLogService(),
        _exerciseService = exerciseService ?? ExerciseService();

  DynamicWorkoutResult? _result;
  bool _isLoading = false;
  String? _error;

  DynamicWorkoutResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RecoveryScore? get recoveryScore => _result?.recoveryScore;
  WorkoutPlan? get todaysWorkout => _result?.todaysWorkout;
  List<Modification> get modifications => _result?.modifications ?? [];
  List<String> get recoveryRecommendations =>
      _result?.recoveryRecommendations ?? [];

  Future<void> generateToday({
    required UserProfile profile,
    required DailyHealthInput dailyInput,
    required WorkoutPlan basePlan,
    double? baselineHrv,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recentLogs = await _logService.getHistory(limit: 30);
      final exerciseCatalog = await _exerciseService.getExercises();

      final result = _engine.generateTodaysWorkout(
        profile: profile,
        dailyInput: dailyInput,
        basePlan: basePlan,
        recentLogs: recentLogs,
        exerciseCatalog: exerciseCatalog,
        baselineHrv: baselineHrv,
      );
      _result = result;
    } catch (e) {
      _error = 'Could not generate today\'s workout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
