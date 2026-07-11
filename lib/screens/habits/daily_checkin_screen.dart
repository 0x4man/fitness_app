import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dynamic_workout_models.dart';
import '../../models/exercise.dart';
import '../../models/user_profile.dart';
import '../../providers/dynamic_workout_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../services/daily_health_service.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/selectable_chip.dart';
import '../workouts/active_workout_screen.dart';
import '../workouts/workout_schedule_screen.dart';

const List<String> _moods = [
  'Motivated',
  'Energized',
  'Neutral',
  'Tired',
  'Stressed',
  'Sore',
];

const List<String> _muscleGroups = [
  'Chest',
  'Back',
  'Legs',
  'Shoulders',
  'Arms',
  'Core',
  'Full Body',
];

/// Daily health check-in — the input side of the Dynamic Workout Engine.
/// Collects sleep, energy, stress, soreness, and today's constraints, saves
/// it via DailyHealthService, then calls DynamicWorkoutProvider to generate
/// and display today's adapted workout.
///
/// Today's base plan is loaded automatically from WorkoutScheduleService —
/// no need to pass one in. If today is a rest day (or no schedule has been
/// set yet), the user is offered a link to build one, or the option to
/// train anyway with a generic full-body session.
class DailyCheckInScreen extends StatefulWidget {
  final UserProfile profile;

  const DailyCheckInScreen({super.key, required this.profile});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _healthService = DailyHealthService();
  final _scheduleService = WorkoutScheduleService();
  final _exerciseService = ExerciseService();

  final _sleepHoursController = TextEditingController(text: '7');
  final _stepsController = TextEditingController(text: '0');
  final _caloriesController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _waterController = TextEditingController(text: '0');
  final _availableTimeController = TextEditingController();

  int _sleepQuality = 6;
  int _energyLevel = 6;
  int _stressLevel = 4;
  String? _selectedMood;
  final Map<String, int> _soreness = {for (final g in _muscleGroups) g: 0};

  bool _isSaving = false;
  bool _isFetchingExisting = false;

  bool _isLoadingPlan = true;
  WorkoutPlan? _todaysPlan;
  List<Exercise> _catalog = [];
  bool _trainAnyway = false;

  @override
  void initState() {
    super.initState();
    _availableTimeController.text =
        widget.profile.preferredDurationMinutes.toString();
    _loadTodaysPlan();
    _loadExistingCheckIn();
  }

  Future<void> _loadTodaysPlan() async {
    final catalog = await _exerciseService.getExercises();
    final plan = await _scheduleService.getTodaysPlan(catalog);
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _todaysPlan = plan;
      _isLoadingPlan = false;
    });
  }

  /// A generic bodyweight full-body session, used only when the user
  /// chooses to train on a scheduled rest day / before any schedule exists.
  WorkoutPlan _fallbackPlan() {
    final picks =
        _catalog.where((e) => e.equipment == 'Bodyweight').take(5).toList();
    final items = picks.map((e) => PlannedExerciseItem.fromCatalog(e)).toList();
    return WorkoutPlan(
      id: 'adhoc-full-body',
      dayLabel: 'Full Body (unscheduled)',
      focusMuscleGroups: items.map((e) => e.muscleGroup).toSet().toList(),
      exercises: items,
    );
  }

  Future<void> _loadExistingCheckIn() async {
    setState(() => _isFetchingExisting = true);
    final existing = await _healthService.getTodayCheckIn();
    if (existing != null && mounted) {
      _sleepHoursController.text = existing.sleepHours.toString();
      _stepsController.text = existing.steps.toString();
      _caloriesController.text = existing.caloriesConsumed.toString();
      _proteinController.text = existing.proteinGrams.toString();
      _waterController.text = existing.waterMl.toString();
      _availableTimeController.text = existing.availableTimeMinutes.toString();
      _sleepQuality = existing.sleepQuality;
      _energyLevel = existing.energyLevel;
      _stressLevel = existing.stressLevel;
      _selectedMood = existing.mood.isNotEmpty ? existing.mood : null;
      for (final entry in existing.soreness.entries) {
        _soreness[entry.key] = entry.value;
      }
    }
    if (mounted) setState(() => _isFetchingExisting = false);
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMood == null) {
      showAppMessage(context, 'Please select your mood.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final input = DailyHealthInput(
        date: DateTime.now(),
        sleepHours: double.parse(_sleepHoursController.text.trim()),
        sleepQuality: _sleepQuality,
        energyLevel: _energyLevel,
        stressLevel: _stressLevel,
        mood: _selectedMood!,
        soreness: Map<String, int>.from(_soreness),
        steps: int.parse(_stepsController.text.trim()),
        caloriesConsumed: int.parse(_caloriesController.text.trim()),
        proteinGrams: double.parse(_proteinController.text.trim()),
        waterMl: double.parse(_waterController.text.trim()),
        availableTimeMinutes: int.parse(_availableTimeController.text.trim()),
      );

      await _healthService.saveCheckIn(input);

      if (!mounted) return;
      final basePlan = _todaysPlan ?? _fallbackPlan();
      await context.read<DynamicWorkoutProvider>().generateToday(
            profile: widget.profile,
            dailyInput: input,
            basePlan: basePlan,
          );
    } catch (e) {
      if (mounted) {
        showAppMessage(
            context, 'Could not generate today\'s workout. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingExisting || _isLoadingPlan) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_todaysPlan == null && !_trainAnyway) {
      return _buildRestDayScreen();
    }

    final workoutProvider = context.watch<DynamicWorkoutProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-In')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How are you today?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps us adapt today\'s workout to how your body actually feels.',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _todaysPlan != null
                        ? 'Scheduled today: ${_todaysPlan!.dayLabel}'
                        : 'No plan scheduled — training with a general full-body session',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Sleep (hours)',
                  hint: '7.5',
                  controller: _sleepHoursController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0 || n > 16) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildSliderSection(
                  'Sleep Quality',
                  _sleepQuality,
                  (v) => setState(() => _sleepQuality = v),
                ),
                _buildSliderSection(
                  'Energy',
                  _energyLevel,
                  (v) => setState(() => _energyLevel = v),
                ),
                _buildSliderSection(
                  'Stress',
                  _stressLevel,
                  (v) => setState(() => _stressLevel = v),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mood',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _moods.map((m) {
                    return SelectableChip(
                      label: m,
                      isSelected: _selectedMood == m,
                      onTap: () => setState(() => _selectedMood = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Muscle Soreness',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '0 = none, 10 = very sore',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                ..._muscleGroups.map((group) => _buildSliderSection(
                      group,
                      _soreness[group] ?? 0,
                      (v) => setState(() => _soreness[group] = v),
                      compact: true,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Steps today',
                        hint: '6500',
                        controller: _stepsController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            int.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Calories',
                        hint: '2200',
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            int.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Protein (g)',
                        hint: '110',
                        controller: _proteinController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) =>
                            double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Water (ml)',
                        hint: '2000',
                        controller: _waterController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) =>
                            double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Available time today (minutes)',
                  hint: '45',
                  controller: _availableTimeController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 240) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                CustomButton(
                  text: 'Generate Today\'s Workout',
                  isLoading: _isSaving || workoutProvider.isLoading,
                  onPressed: _handleGenerate,
                ),
                const SizedBox(height: 24),
                if (workoutProvider.error != null)
                  Text(workoutProvider.error!,
                      style: const TextStyle(color: Colors.red)),
                if (workoutProvider.result != null)
                  _buildResultSummary(workoutProvider),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 12),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 90 : 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: compact ? 0 : 1,
              max: 10,
              divisions: compact ? 10 : 9,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text('$value', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary(DynamicWorkoutProvider provider) {
    final result = provider.result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Score: ${result.recoveryScore.score.round()}/100 '
            '(${result.recoveryScore.readiness.label})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Today: ${result.todaysWorkout.dayLabel} · '
            '~${result.estimatedDurationMinutes.round()} min',
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (result.wasModified) ...[
            const SizedBox(height: 16),
            const Text('Modifications',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...result.modifications.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${m.summary}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(m.reason,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                )),
          ],
          if (result.recoveryRecommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Recovery Tips',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...result.recoveryRecommendations.map(
                (tip) => Text('• $tip', style: const TextStyle(fontSize: 13))),
          ],
          const SizedBox(height: 16),
          const Text('Today\'s Exercises',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...result.todaysWorkout.exercises.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.exercise.name,
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.textPrimary)),
                    ),
                    Text('${item.sets} × ${item.reps}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Start This Workout',
            onPressed: () {
              context
                  .read<WorkoutSessionProvider>()
                  .loadFromPlan(result.todaysWorkout);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.self_improvement,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 20),
              const Text(
                'Today\'s a rest day',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nothing\'s scheduled for today — either by design, or because '
                'a weekly schedule hasn\'t been set up yet.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Set Up Weekly Schedule',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkoutScheduleScreen()),
                  );
                  _loadTodaysPlan();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() => _trainAnyway = true),
                child: const Text('Train Anyway'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sleepHoursController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _waterController.dispose();
    _availableTimeController.dispose();
    super.dispose();
  }
}
