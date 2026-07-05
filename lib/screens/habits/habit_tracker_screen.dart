import 'package:flutter/material.dart';
import '../../models/habit_log.dart';
import '../../services/habit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/habit_progress_row.dart';

/// Habit Tracker — log Water Intake, Sleep, and Protein for today,
/// with quick-add controls and a 7-day consistency strip.
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

  Future<void> _refreshWeekSilently() async {
    final week = await _habitService.getLastSevenDays();
    if (mounted) setState(() => _week = week);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _today == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = _today!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const AppHeader(),
              const SizedBox(height: 18),
              const Text(
                'Today\'s Habits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Small daily habits, big results.',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 20),

              // Weekly consistency strip
              _WeekStrip(week: _week),
              const SizedBox(height: 24),

              // Water
              _HabitCard(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF3B82F6),
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
                color: const Color(0xFF8B5CF6),
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
                color: AppColors.accent,
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
              const SizedBox(height: 12),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(week.length, (i) {
          final log = week[i];
          final isToday = i == week.length - 1;
          final progress =
              ((log.waterGlasses / HabitGoals.waterGlasses).clamp(0.0, 1.0) +
                      (log.sleepHours / HabitGoals.sleepHours).clamp(0.0, 1.0) +
                      (log.proteinGrams / HabitGoals.proteinGrams)
                          .clamp(0.0, 1.0)) /
                  3;
          final color =
              Color.lerp(AppColors.surfaceBorder, AppColors.accent, progress)!;

          return Column(
            children: [
              Text(
                _dayLabels[DateTime.parse(log.date).weekday - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isToday ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: progress > 0 ? 1 : 0.15),
                  border: isToday
                      ? Border.all(color: AppColors.accent, width: 1.5)
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
  final Color color;
  final String title;
  final String valueText;
  final double progress;
  final Widget child;

  const _HabitCard({
    required this.icon,
    required this.color,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HabitProgressRow(
            icon: icon,
            label: title,
            valueText: valueText,
            progress: progress,
            color: color,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? c : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: filled ? c : AppColors.surfaceBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled
                  ? (darkText ? Colors.black : Colors.white)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
