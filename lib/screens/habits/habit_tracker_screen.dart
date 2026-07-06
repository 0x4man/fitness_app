import 'package:flutter/material.dart';
import '../../models/habit_log.dart';
import '../../services/habit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/habit_progress_row.dart';
import '../profile/profile_screen.dart';

/// Habit Tracker — log Water Intake, Sleep, Protein, and Calories for
/// today, with quick-add controls, a 7-day consistency strip, and an
/// overall daily progress summary up top.
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
  }

  Future<void> _updateWater(int delta) async {
    final current = _today!;
    final updated = current.copyWith(
      waterGlasses: (current.waterGlasses + delta).clamp(0, 99),
    );
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    _refreshWeekSilently();
  }

  Future<void> _setSleep(double hours) async {
    final updated = _today!.copyWith(sleepHours: hours);
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    _refreshWeekSilently();
  }

  Future<void> _updateProtein(int delta) async {
    final current = _today!;
    final updated = current.copyWith(
      proteinGrams: (current.proteinGrams + delta).clamp(0, 999),
    );
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    _refreshWeekSilently();
  }

  Future<void> _updateCalories(int delta) async {
    final current = _today!;
    final updated = current.copyWith(
      caloriesKcal: (current.caloriesKcal + delta).clamp(0, 9999),
    );
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    _refreshWeekSilently();
  }

  Future<void> _refreshWeekSilently() async {
    final week = await _habitService.getLastSevenDays();
    if (mounted) setState(() => _week = week);
  }

  double _overallProgress(HabitLog log) {
    return ((log.waterGlasses / _waterGoal).clamp(0.0, 1.0) +
            (log.sleepHours / _sleepGoal).clamp(0.0, 1.0) +
            (log.proteinGrams / _proteinGoal).clamp(0.0, 1.0) +
            (log.caloriesKcal / _caloriesGoal).clamp(0.0, 1.0)) /
        4;
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
    if (_isLoading || _today == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = _today!;
    final overall = _overallProgress(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              AppHeader(
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
              const SizedBox(height: 22),
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

              // Weekly consistency strip
              _WeekStrip(
                week: _week,
                waterGoal: _waterGoal,
                sleepGoal: _sleepGoal,
                proteinGoal: _proteinGoal,
                caloriesGoal: _caloriesGoal,
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
                    _QuickButton(
                        label: '+2 glasses', onTap: () => _updateWater(2)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Sleep — FIXED: preset buttons are now direct Row children
              // (no Padding wrapper), so _QuickButton's internal Expanded
              // always has a valid Row/Column parent. Filled state is now
              // dynamic, matching today's actual logged sleep value.
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
              const SizedBox(height: 14),

              // Protein
              _HabitCard(
                icon: Icons.egg_alt_rounded,
                gradient: AppColors.heroGradient,
                title: 'Protein',
                valueText: '${today.proteinGrams} / $_proteinGoal g',
                progress: (today.proteinGrams / _proteinGoal).clamp(0.0, 1.0),
                onEditGoal: () => _editGoal(
                  title: 'Protein',
                  unit: 'g',
                  currentValue: _proteinGoal,
                  isDouble: false,
                  onSave: (v) => setState(() => _proteinGoal = v.toInt()),
                ),
                child: Row(
                  children: [
                    _QuickButton(
                        label: '-10g', onTap: () => _updateProtein(-10)),
                    const SizedBox(width: 8),
                    _QuickButton(
                        label: '+10g', onTap: () => _updateProtein(10)),
                    const SizedBox(width: 8),
                    _QuickButton(
                        label: '+25g',
                        onTap: () => _updateProtein(25),
                        filled: true,
                        color: AppColors.accent,
                        darkText: true),
                    const SizedBox(width: 8),
                    _QuickButton(
                        label: '+50g', onTap: () => _updateProtein(50)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Calories
              _HabitCard(
                icon: Icons.local_fire_department_rounded,
                gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                title: 'Calories',
                valueText: '${today.caloriesKcal} / $_caloriesGoal kcal',
                progress: (today.caloriesKcal / _caloriesGoal).clamp(0.0, 1.0),
                onEditGoal: () => _editGoal(
                  title: 'Calories',
                  unit: 'kcal',
                  currentValue: _caloriesGoal,
                  isDouble: false,
                  onSave: (v) => setState(() => _caloriesGoal = v.toInt()),
                ),
                child: Row(
                  children: [
                    _QuickButton(
                        label: '-100', onTap: () => _updateCalories(-100)),
                    const SizedBox(width: 8),
                    _QuickButton(
                        label: '+100', onTap: () => _updateCalories(100)),
                    const SizedBox(width: 8),
                    _QuickButton(
                        label: '+250',
                        onTap: () => _updateCalories(250),
                        filled: true,
                        color: const Color(0xFFF59E0B),
                        darkText: true),
                    const SizedBox(width: 8),
                    _QuickButton(
                        label: '+500', onTap: () => _updateCalories(500)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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

  const _WeekStrip({
    required this.week,
    required this.waterGoal,
    required this.sleepGoal,
    required this.proteinGoal,
    required this.caloriesGoal,
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

          return Column(
            children: [
              Text(
                _dayLabels[DateTime.parse(log.date).weekday - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      isToday ? AppColors.textPrimary : AppColors.textSecondary,
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
          );
        }),
      ),
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
                child: HabitProgressRow(
                  icon: icon,
                  label: title,
                  valueText: valueText,
                  progress: progress,
                  color: gradient.last,
                ),
              ),
              if (onEditGoal != null)
                IconButton(
                  onPressed: onEditGoal,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  tooltip: 'Edit goal',
                ),
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
