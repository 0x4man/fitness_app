import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/workout_schedule.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Lets the user define their weekly training split once — "Monday = Push,
/// Tuesday = Rest, ..." — which the Dynamic Workout Engine then reads as
/// "today's base plan" every day via WorkoutScheduleService.getTodaysPlan().
class WorkoutScheduleScreen extends StatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> {
  final _scheduleService = WorkoutScheduleService();
  final _exerciseService = ExerciseService();

  WorkoutSchedule? _schedule;
  List<Exercise> _catalog = [];
  final Map<String, TextEditingController> _labelControllers = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final schedule = await _scheduleService.getSchedule();
    final catalog = await _exerciseService.getExercises();
    if (!mounted) return;
    for (final name in weekdayNames) {
      _labelControllers[name] =
          TextEditingController(text: schedule.days[name]?.dayLabel ?? '');
    }
    setState(() {
      _schedule = schedule;
      _catalog = catalog;
      _isLoading = false;
    });
  }

  void _updateDay(ScheduledDay day) {
    setState(() => _schedule = _schedule!.updateDay(day));
  }

  Future<void> _handleSave() async {
    if (_schedule == null) return;
    setState(() => _isSaving = true);
    try {
      // Pull the latest label text into the schedule before saving.
      var schedule = _schedule!;
      for (final name in weekdayNames) {
        final day = schedule.days[name]!;
        if (!day.isRestDay) {
          schedule = schedule.updateDay(
              day.copyWith(dayLabel: _labelControllers[name]!.text.trim()));
        }
      }
      await _scheduleService.saveSchedule(schedule);
      if (mounted) {
        showAppMessage(context, 'Schedule saved.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Could not save schedule. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openExercisePicker(ScheduledDay day) async {
    final alreadyAddedIds = day.exercises.map((e) => e.exerciseId).toSet();
    final result = await showModalBottomSheet<List<Exercise>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePickerSheet(
        catalog: _catalog,
        alreadySelectedIds: alreadyAddedIds,
      ),
    );
    if (result == null || result.isEmpty) return;

    final newExercises = [
      ...day.exercises,
      ...result.map((ex) => ScheduledExercise.fromExercise(ex)),
    ];
    _updateDay(day.copyWith(exercises: newExercises));
  }

  void _removeExercise(ScheduledDay day, String exerciseId) {
    _updateDay(day.copyWith(
      exercises:
          day.exercises.where((e) => e.exerciseId != exerciseId).toList(),
    ));
  }

  void _adjustSets(ScheduledDay day, String exerciseId, int delta) {
    final updated = day.exercises.map((e) {
      if (e.exerciseId != exerciseId) return e;
      final newSets = (e.sets + delta).clamp(1, 10).toInt();
      return e.copyWith(sets: newSets);
    }).toList();
    _updateDay(day.copyWith(exercises: updated));
  }

  void _adjustReps(ScheduledDay day, String exerciseId, int delta) {
    final updated = day.exercises.map((e) {
      if (e.exerciseId != exerciseId) return e;
      final newReps = (e.reps + delta).clamp(1, 50).toInt();
      return e.copyWith(reps: newReps);
    }).toList();
    _updateDay(day.copyWith(exercises: updated));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _schedule == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            const Text(
              'Set your split once — the Dynamic Workout Engine adapts '
              'each day\'s session from here based on how you\'re feeling.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...weekdayNames
                .map((name) => _buildDayCard(_schedule!.days[name]!)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Save Schedule',
            isLoading: _isSaving,
            onPressed: _handleSave,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(ScheduledDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          day.dayOfWeek,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          day.isRestDay
              ? 'Rest day'
              : (day.dayLabel.isNotEmpty
                  ? '${day.dayLabel} · ${day.exercises.length} exercises'
                  : '${day.exercises.length} exercises'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rest day'),
                  value: day.isRestDay,
                  onChanged: (v) => _updateDay(day.copyWith(isRestDay: v)),
                ),
                if (!day.isRestDay) ...[
                  CustomTextField(
                    label: 'Day label',
                    hint: 'e.g. Push Day',
                    controller: _labelControllers[day.dayOfWeek]!,
                  ),
                  const SizedBox(height: 16),
                  if (day.exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No exercises added yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ...day.exercises.map((ex) => _buildExerciseRow(day, ex)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openExercisePicker(day),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Exercises'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(ScheduledDay day, ScheduledExercise ex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(ex.muscleGroup,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _stepper('Sets', ex.sets, () => _adjustSets(day, ex.exerciseId, -1),
              () => _adjustSets(day, ex.exerciseId, 1)),
          const SizedBox(width: 8),
          _stepper('Reps', ex.reps, () => _adjustReps(day, ex.exerciseId, -1),
              () => _adjustReps(day, ex.exerciseId, 1)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _removeExercise(day, ex.exerciseId),
          ),
        ],
      ),
    );
  }

  Widget _stepper(
      String label, int value, VoidCallback onMinus, VoidCallback onPlus) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
                onTap: onMinus,
                child: const Icon(Icons.remove_circle_outline, size: 18)),
            SizedBox(
              width: 22,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ),
            InkWell(
                onTap: onPlus,
                child: const Icon(Icons.add_circle_outline, size: 18)),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Modal sheet for picking exercises to add to a day, grouped by muscle
/// group with a filter chip row at the top.
class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> catalog;
  final Set<String> alreadySelectedIds;

  const _ExercisePickerSheet({
    required this.catalog,
    required this.alreadySelectedIds,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String? _muscleFilter;
  final Set<String> _picked = {};

  @override
  Widget build(BuildContext context) {
    final muscleGroups =
        widget.catalog.map((e) => e.muscleGroup).toSet().toList()..sort();
    final visible = widget.catalog
        .where((e) => _muscleFilter == null || e.muscleGroup == _muscleFilter)
        .where((e) => !widget.alreadySelectedIds.contains(e.id))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Add Exercises',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('All', _muscleFilter == null,
                        () => setState(() => _muscleFilter = null)),
                    ...muscleGroups.map((g) => _filterChip(
                        g,
                        _muscleFilter == g,
                        () => setState(() => _muscleFilter = g))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final ex = visible[i];
                    final selected = _picked.contains(ex.id);
                    return CheckboxListTile(
                      title: Text(ex.name),
                      subtitle: Text(
                          '${ex.muscleGroup} · ${ex.equipment} · ${ex.difficulty}'),
                      value: selected,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _picked.add(ex.id);
                        } else {
                          _picked.remove(ex.id);
                        }
                      }),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: _picked.isEmpty
                      ? 'Select exercises'
                      : 'Add ${_picked.length} exercise${_picked.length == 1 ? '' : 's'}',
                  onPressed: () {
                    if (_picked.isEmpty) return;
                    final selected = widget.catalog
                        .where((e) => _picked.contains(e.id))
                        .toList();
                    Navigator.of(context).pop(selected);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
