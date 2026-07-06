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

  @override
  void initState() {
    super.initState();
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
    return ((log.waterGlasses / HabitGoals.waterGlasses).clamp(0.0, 1.0) +
            (log.sleepHours / HabitGoals.sleepHours).clamp(0.0, 1.0) +
            (log.proteinGrams / HabitGoals.proteinGrams).clamp(0.0, 1.0) +
            (log.caloriesKcal / HabitGoals.caloriesKcal).clamp(0.0, 1.0)) /
        4;
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
              _WeekStrip(week: _week),
              const SizedBox(height: 24),

              // Water
              _HabitCard(
                icon: Icons.water_drop_rounded,
                gradient: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                title: 'Water Intake',
                valueText:
                    '${today.waterGlasses} / ${HabitGoals.waterGlasses} glasses',
                progress: (today.waterGlasses / HabitGoals.waterGlasses)
                    .clamp(0.0, 1.0),
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

              // Sleep
              _HabitCard(
                icon: Icons.bedtime_rounded,
                gradient: const [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                title: 'Sleep',
                valueText:
                    '${today.sleepHours.toStringAsFixed(1)} / ${HabitGoals.sleepHours.toStringAsFixed(0)} hrs',
                progress:
                    (today.sleepHours / HabitGoals.sleepHours).clamp(0.0, 1.0),
                child: Row(
                  children: [6, 7, 8, 9].map((h) {
                    final isSelected = today.sleepHours == h.toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickButton(
                        label: '${h}h',
                        onTap: () => _setSleep(h.toDouble()),
                        filled: isSelected,
                        color: const Color(0xFF8B5CF6),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Protein
              _HabitCard(
                icon: Icons.egg_alt_rounded,
                gradient: AppColors.heroGradient,
                title: 'Protein',
                valueText:
                    '${today.proteinGrams} / ${HabitGoals.proteinGrams} g',
                progress: (today.proteinGrams / HabitGoals.proteinGrams)
                    .clamp(0.0, 1.0),
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
                valueText:
                    '${today.caloriesKcal} / ${HabitGoals.caloriesKcal} kcal',
                progress: (today.caloriesKcal / HabitGoals.caloriesKcal)
                    .clamp(0.0, 1.0),
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

  const _WeekStrip({required this.week});

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
          final progress = ((log.waterGlasses / HabitGoals.waterGlasses)
                      .clamp(0.0, 1.0) +
                  (log.sleepHours / HabitGoals.sleepHours).clamp(0.0, 1.0) +
                  (log.proteinGrams / HabitGoals.proteinGrams).clamp(0.0, 1.0) +
                  (log.caloriesKcal / HabitGoals.caloriesKcal)
                      .clamp(0.0, 1.0)) /
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

  const _HabitCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.valueText,
    required this.progress,
    required this.child,
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
