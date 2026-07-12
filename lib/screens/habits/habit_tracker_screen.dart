import 'package:flutter/material.dart';
import '../../models/habit_log.dart';
import '../../services/habit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../profile/profile_screen.dart';
import 'nutrition_tracker_view.dart';

/// Habit Tracker — log Water Intake, Sleep, Protein, and Calories for
/// today, with quick-add controls, a 7-day consistency strip (tap any
/// day to see that day's full breakdown), and an overall daily
/// progress summary up top.
///
/// Goals for each habit can be customized by the user (tap the small
/// edit icon next to any habit's target). Custom goals are kept in
/// memory for this session — wire them up to HabitService if you want
/// them to persist across app restarts.
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final _habitService = HabitService();
  HabitLog? _today;
  List<HabitLog> _week = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _viewIndex = 0; // 0 = Daily Habits, 1 = Nutrition

  // User-editable goals. Defaulted from HabitGoals, but overridable.
  late int _waterGoal;
  late double _sleepGoal;
  late int _proteinGoal;
  late int _caloriesGoal;

  @override
  void initState() {
    super.initState();
    _waterGoal = HabitGoals.waterGlasses;
    _sleepGoal = HabitGoals.sleepHours;
    _proteinGoal = HabitGoals.proteinGrams;
    _caloriesGoal = HabitGoals.caloriesKcal;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _habitService.getTodayLog(),
        _habitService.getLastSevenDays(),
      ]);
      if (mounted) {
        setState(() {
          _today = results[0] as HabitLog;
          _week = results[1] as List<HabitLog>;
          _isLoading = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('HabitTrackerScreen load error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateWater(int delta) async {
    // Fetch the latest saved doc first — not the possibly-stale cached
    // _today — so a write here never clobbers calories/protein/carbs/fat
    // that may have just been added from the Nutrition tab.
    final latest = await _habitService.getTodayLog();
    final updated = latest.copyWith(
      waterGlasses: (latest.waterGlasses + delta).clamp(0, _waterGoal),
    );
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    _refreshWeekSilently();
  }

  Future<void> _setSleep(double hours) async {
    final latest = await _habitService.getTodayLog();
    final updated = latest.copyWith(sleepHours: hours);
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    _refreshWeekSilently();
  }

  Future<void> _refreshWeekSilently() async {
    final week = await _habitService.getLastSevenDays();
    if (mounted) setState(() => _week = week);
  }

  Future<void> _refreshTodaySilently() async {
    final today = await _habitService.getTodayLog();
    if (mounted) setState(() => _today = today);
  }

  double _overallProgress(HabitLog log) {
    return ((log.waterGlasses / _waterGoal).clamp(0.0, 1.0) +
            (log.sleepHours / _sleepGoal).clamp(0.0, 1.0) +
            (log.proteinGrams / _proteinGoal).clamp(0.0, 1.0) +
            (log.caloriesKcal / _caloriesGoal).clamp(0.0, 1.0)) /
        4;
  }

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _monthNames = [
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
    'Dec',
  ];

  String _formatFullDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    return '${_weekdayNames[d.weekday - 1]}, ${_monthNames[d.month - 1]} ${d.day}';
  }

  /// Opens a bottom sheet showing the full breakdown for a tapped day
  /// from the weekly consistency strip.
  void _showDayDetails(HabitLog log) {
    final now = DateTime.now();
    final isToday = log.date == _habitService.formatDate(now);
    final progress = _overallProgress(log);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday ? 'Today' : _formatFullDate(log.date),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DayDetailRow(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF3B82F6),
                label: 'Water',
                valueText: '${log.waterGlasses} / $_waterGoal glasses',
                progress: (log.waterGlasses / _waterGoal).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 14),
              _DayDetailRow(
                icon: Icons.bedtime_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'Sleep',
                valueText:
                    '${log.sleepHours.toStringAsFixed(1)} / ${_sleepGoal.toStringAsFixed(0)} hrs',
                progress: _sleepGoal > 0
                    ? (log.sleepHours / _sleepGoal).clamp(0.0, 1.0)
                    : 0.0,
              ),
              const SizedBox(height: 14),
              _DayDetailRow(
                icon: Icons.egg_alt_rounded,
                color: AppColors.accent,
                label: 'Protein',
                valueText: '${log.proteinGrams} / $_proteinGoal g',
                progress: (log.proteinGrams / _proteinGoal).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 14),
              _DayDetailRow(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF59E0B),
                label: 'Calories',
                valueText: '${log.caloriesKcal} / $_caloriesGoal kcal',
                progress: (log.caloriesKcal / _caloriesGoal).clamp(0.0, 1.0),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Generic dialog to let the user set a custom goal/target for a habit.
  Future<void> _editGoal({
    required String title,
    required String unit,
    required num currentValue,
    required bool isDouble,
    required void Function(num newValue) onSave,
  }) async {
    final controller = TextEditingController(
      text: isDouble
          ? currentValue.toStringAsFixed(1)
          : currentValue.toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Set $title Goal',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final parsed = num.tryParse(controller.text.trim());
                if (parsed != null && parsed > 0) {
                  onSave(parsed);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _today == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Could not load your habits.\n${_errorMessage ?? 'Unknown error'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final today = _today!;
    final overall = _overallProgress(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AppHeader(
                onNotificationTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                onAvatarTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionToggle(
                selectedIndex: _viewIndex,
                labels: const ['Daily Habits', 'Nutrition'],
                onChanged: (i) {
                  setState(() => _viewIndex = i);
                  if (i == 0) _refreshTodaySilently();
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _viewIndex == 0
                  ? _buildHabitsBody(today, overall)
                  : const NutritionTrackerView(),
            ),
          ],
        ),
      ),
    );
  }

  /// Everything that was originally in build() below the header — moved
  /// here unchanged so the existing Daily Habits view behaves exactly as
  /// before. Only the AppHeader (now static above the toggle) was removed
  /// from this block.
  Widget _buildHabitsBody(HabitLog today, double overall) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Text(
            'Today\'s Habits',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Small daily habits, big results.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 22),

          // Hero overall-progress summary
          _OverallProgressCard(progress: overall),
          const SizedBox(height: 20),

          // Weekly consistency strip — tap any day to see its breakdown
          _WeekStrip(
            week: _week,
            waterGoal: _waterGoal,
            sleepGoal: _sleepGoal,
            proteinGoal: _proteinGoal,
            caloriesGoal: _caloriesGoal,
            onDayTap: _showDayDetails,
          ),
          const SizedBox(height: 24),

          // Water
          _HabitCard(
            icon: Icons.water_drop_rounded,
            gradient: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            title: 'Water Intake',
            valueText: '${today.waterGlasses} / $_waterGoal glasses',
            progress: (today.waterGlasses / _waterGoal).clamp(0.0, 1.0),
            onEditGoal: () => _editGoal(
              title: 'Water',
              unit: 'glasses',
              currentValue: _waterGoal,
              isDouble: false,
              onSave: (v) => setState(() => _waterGoal = v.toInt()),
            ),
            child: Row(
              children: [
                _QuickButton(label: '-1', onTap: () => _updateWater(-1)),
                const SizedBox(width: 8),
                _QuickButton(
                    label: '+1 glass',
                    onTap: () => _updateWater(1),
                    filled: true,
                    color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _QuickButton(label: '+2 glasses', onTap: () => _updateWater(2)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Sleep
          _HabitCard(
            icon: Icons.bedtime_rounded,
            gradient: const [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
            title: 'Sleep',
            valueText:
                '${today.sleepHours.toStringAsFixed(1)} / ${_sleepGoal.toStringAsFixed(0)} hrs',
            progress: _sleepGoal > 0
                ? (today.sleepHours / _sleepGoal).clamp(0.0, 1.0)
                : 0.0,
            onEditGoal: () => _editGoal(
              title: 'Sleep',
              unit: 'hrs',
              currentValue: _sleepGoal,
              isDouble: true,
              onSave: (v) => setState(() => _sleepGoal = v.toDouble()),
            ),
            child: Row(
              children: [
                _QuickButton(
                    label: '6h',
                    onTap: () => _setSleep(6.0),
                    filled: today.sleepHours == 6.0,
                    color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _QuickButton(
                    label: '7h',
                    onTap: () => _setSleep(7.0),
                    filled: today.sleepHours == 7.0,
                    color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _QuickButton(
                    label: '8h',
                    onTap: () => _setSleep(8.0),
                    filled: today.sleepHours == 8.0,
                    color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _QuickButton(
                    label: '9h',
                    onTap: () => _setSleep(9.0),
                    filled: today.sleepHours == 9.0,
                    color: const Color(0xFF8B5CF6)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Small pill-style segmented toggle used to switch between Daily
/// Habits and Nutrition, styled consistently with the filter chips
/// used elsewhere in the app.
class _SectionToggle extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SectionToggle({
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: AppColors.heroGradient)
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Hero card at the top showing today's combined completion across all
/// four habits, as a single glanceable ring + message.
class _OverallProgressCard extends StatelessWidget {
  final double progress; // 0.0 - 1.0

  const _OverallProgressCard({required this.progress});

  String get _message {
    if (progress >= 1.0) return 'Perfect day. You showed up 💪';
    if (progress >= 0.7) return 'Almost there — keep going!';
    if (progress >= 0.4) return 'Good start, don\'t stop now.';
    return 'Let\'s get today moving.';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final List<HabitLog> week;
  final int waterGoal;
  final double sleepGoal;
  final int proteinGoal;
  final int caloriesGoal;
  final ValueChanged<HabitLog> onDayTap;

  const _WeekStrip({
    required this.week,
    required this.waterGoal,
    required this.sleepGoal,
    required this.proteinGoal,
    required this.caloriesGoal,
    required this.onDayTap,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(week.length, (i) {
          final log = week[i];
          final isToday = i == week.length - 1;
          final progress = ((log.waterGlasses / waterGoal).clamp(0.0, 1.0) +
                  (log.sleepHours / sleepGoal).clamp(0.0, 1.0) +
                  (log.proteinGrams / proteinGoal).clamp(0.0, 1.0) +
                  (log.caloriesKcal / caloriesGoal).clamp(0.0, 1.0)) /
              4;
          final color =
              Color.lerp(AppColors.surfaceBorder, AppColors.accent, progress)!;

          return GestureDetector(
            onTap: () => onDayTap(log),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Text(
                    _dayLabels[DateTime.parse(log.date).weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: progress > 0 ? 1 : 0.12),
                      border: isToday
                          ? Border.all(color: Colors.white, width: 1.5)
                          : null,
                      boxShadow: progress > 0.5
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: progress >= 0.99
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.black)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// One row in the day-detail bottom sheet — icon, label, value vs goal,
/// and a thin progress bar. Purely presentational.
class _DayDetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String valueText;
  final double progress;

  const _DayDetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.valueText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  Text(valueText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String valueText;
  final double progress;
  final Widget child;
  final VoidCallback? onEditGoal;

  const _HabitCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.valueText,
    required this.progress,
    required this.child,
    this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.last.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(gradient.last),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEditGoal != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onEditGoal,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  tooltip: 'Edit goal',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;
  final bool darkText;

  const _QuickButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
    this.darkText = false,
  });

  @override
  State<_QuickButton> createState() => _QuickButtonState();
}

class _QuickButtonState extends State<_QuickButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.filled ? c : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.filled ? c : AppColors.surfaceBorder),
              boxShadow: widget.filled
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: widget.filled
                    ? (widget.darkText ? Colors.black : Colors.white)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
