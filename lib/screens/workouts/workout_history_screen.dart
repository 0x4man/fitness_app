import 'package:flutter/material.dart';
import '../../models/workout_log.dart';
import '../../services/workout_log_service.dart';
import '../../theme/app_theme.dart';

/// Shows the user's past completed workouts, most recent first. Tap
/// any entry to see the full breakdown (every exercise and set).
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final _service = WorkoutLogService();
  List<WorkoutLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _service.getHistory();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _exerciseSummary(WorkoutLog log) {
    if (log.exercises.isEmpty) return 'No exercises logged';
    final names = log.exercises.map((e) => e.name).toList();
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2} more';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Workout History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text(
                    'No workouts logged yet.',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkoutDetailScreen(
                                  log: log, dateLabel: _formatDate(log.date)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.surfaceBorder),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(Icons.fitness_center_rounded,
                                    color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(log.date),
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _exerciseSummary(log),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${log.exercises.length} exercises · ${log.totalSets} sets · ${log.durationMinutes} min',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Full breakdown of a single completed workout — every exercise and
/// every set (reps/weight), opened by tapping an entry in history.
class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutLog log;
  final String dateLabel;

  const WorkoutDetailScreen(
      {super.key, required this.log, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(dateLabel)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(
                    label: 'Exercises', value: '${log.exercises.length}'),
                _SummaryStat(label: 'Total Sets', value: '${log.totalSets}'),
                _SummaryStat(
                    label: 'Duration', value: '${log.durationMinutes} min'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (log.exercises.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'No exercise details were saved for this workout.',
                  style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.85)),
                ),
              ),
            )
          else
            ...log.exercises.map((exercise) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        exercise.muscleGroup,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          SizedBox(
                              width: 36,
                              child: Text('Set', style: _headerStyle)),
                          Expanded(child: Text('Reps', style: _headerStyle)),
                          Expanded(child: Text('Weight', style: _headerStyle)),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.surfaceBorder),
                      ...exercise.sets.asMap().entries.map((entry) {
                        final i = entry.key;
                        final set = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              Expanded(
                                child: Text('${set.reps}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary)),
                              ),
                              Expanded(
                                child: Text(
                                  set.weight > 0
                                      ? '${set.weight.toStringAsFixed(0)} kg'
                                      : 'Bodyweight',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
        ),
      ],
    );
  }
}
