import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_log.dart';
import '../../providers/workout_session_provider.dart';
import '../../services/workout_log_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';

/// Screen for the in-progress "Today's Workout" — lets the user log
/// actual reps/weight per set, check off completed sets, add/remove
/// sets or exercises, and finish (save) or discard the session.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _workoutLogService = WorkoutLogService();
  final DateTime _startTime = DateTime.now();
  bool _isSaving = false;

  Future<void> _finishWorkout(WorkoutSessionProvider session) async {
    if (session.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final durationMinutes = DateTime.now().difference(_startTime).inMinutes;
      final log = WorkoutLog(
        id: '',
        date: DateTime.now(),
        durationMinutes: durationMinutes < 1 ? 1 : durationMinutes,
        exercises: session.exercises
            .map((tracked) => LoggedExercise(
                  exerciseId: tracked.exercise.id,
                  name: tracked.exercise.name,
                  muscleGroup: tracked.exercise.muscleGroup,
                  sets: tracked.sets
                      .map((s) => LoggedSet(reps: s.reps, weight: s.weight))
                      .toList(),
                ))
            .toList(),
      );

      await _workoutLogService.saveWorkout(log);
      session.clear();

      if (!mounted) return;
      // Pop all the way back to the root route instead of a single pop.
      // A single pop() would land back on whatever pushed this screen —
      // e.g. the Daily Check-In form — which felt like the app was
      // asking for "available time" all over again. This always returns
      // straight to the main app shell (Home tab) regardless of how the
      // workout was started (Workout Library, Daily Check-In, etc).
      Navigator.of(context).popUntil((route) => route.isFirst);
      showAppMessage(context, 'Workout saved! 💪', isError: false);
    } catch (e) {
      if (mounted) showAppMessage(context, 'Could not save workout: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDiscard(WorkoutSessionProvider session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text(
            'This will remove all exercises from your current session.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              session.clear();
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context)
                  .popUntil((route) => route.isFirst); // back to Home
            },
            child:
                const Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutSessionProvider>(
      builder: (context, session, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Today\'s Workout'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (!session.isEmpty)
                TextButton(
                  onPressed: () => _confirmDiscard(session),
                  child: const Text('Discard',
                      style: TextStyle(color: AppColors.error)),
                ),
            ],
          ),
          body: session.isEmpty
              ? Center(
                  child: Text(
                    'No exercises added yet.\nGo back and add some from the library.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: session.exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, exerciseIndex) {
                    final tracked = session.exercises[exerciseIndex];
                    return _ExerciseTrackerCard(
                      exerciseIndex: exerciseIndex,
                      tracked: tracked,
                      session: session,
                    );
                  },
                ),
          bottomNavigationBar: session.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSaving ? null : () => _finishWorkout(session),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Finish Workout'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _ExerciseTrackerCard extends StatelessWidget {
  final int exerciseIndex;
  final TrackedExercise tracked;
  final WorkoutSessionProvider session;

  const _ExerciseTrackerCard({
    required this.exerciseIndex,
    required this.tracked,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracked.exercise.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      tracked.exercise.muscleGroup,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textSecondary),
                onPressed: () => session.removeExercise(exerciseIndex),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Column header row
          const Row(
            children: [
              SizedBox(width: 36, child: Text('Set', style: _headerStyle)),
              Expanded(child: Center(child: Text('Reps', style: _headerStyle))),
              Expanded(
                  child:
                      Center(child: Text('Weight (kg)', style: _headerStyle))),
              SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 4),
          ...tracked.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${setIndex + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SetInputField(
                      initialValue: set.reps.toString(),
                      onChanged: (value) => session.updateReps(
                        exerciseIndex,
                        setIndex,
                        int.tryParse(value) ?? set.reps,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SetInputField(
                      initialValue:
                          set.weight == 0 ? '' : set.weight.toStringAsFixed(0),
                      hint: '0',
                      onChanged: (value) => session.updateWeight(
                        exerciseIndex,
                        setIndex,
                        double.tryParse(value) ?? set.weight,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        set.completed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: set.completed
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () =>
                          session.toggleSetComplete(exerciseIndex, setIndex),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => session.addSet(exerciseIndex),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Set'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 10.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

class _SetInputField extends StatelessWidget {
  final String initialValue;
  final String? hint;
  final ValueChanged<String> onChanged;

  const _SetInputField(
      {required this.initialValue, this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
