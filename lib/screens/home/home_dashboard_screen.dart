import 'package:flutter/material.dart';
import '../../models/habit_log.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/habit_service.dart';
import '../../services/profile_service.dart';
import '../../services/workout_log_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/habit_progress_row.dart';
import '../habits/daily_checkin_screen.dart';
import '../profile/profile_screen.dart';
import '../workouts/workout_schedule_screen.dart';

/// The main Home tab: branded header, greeting, BMI (calculated from
/// the user's saved profile), a placeholder streak/today's-workout
/// summary, and a quick-start CTA. Workout/habit data will populate
/// the placeholder cards once the Workout Tracker and Habit Tracker
/// are built.
class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onStartWorkout;
  final VoidCallback? onViewHabits;

  const HomeDashboardScreen(
      {super.key, this.onStartWorkout, this.onViewHabits});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _profileService = ProfileService();
  final _workoutLogService = WorkoutLogService();
  final _habitService = HabitService();
  UserProfile? _profile;
  HabitLog? _todayHabits;
  int _streak = 0;
  int _workoutsThisWeek = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _profileService.getProfile(),
      _workoutLogService.getCurrentStreak(),
      _workoutLogService.getWorkoutsThisWeek(),
      _habitService.getTodayLog(),
    ]);
    if (mounted) {
      setState(() {
        _profile = results[0] as UserProfile?;
        _streak = results[1] as int;
        _workoutsThisWeek = results[2] as int;
        _todayHabits = results[3] as HabitLog;
        _isLoading = false;
      });
    }
  }

  String get _greetingName {
    final user = AuthService().currentUser;
    final name = user?.displayName;
    if (name == null || name.trim().isEmpty) return 'Athlete';
    return name.split(' ').first;
  }

  String get _greetingTime {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  ({String label, Color color}) _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return (label: 'Underweight', color: const Color(0xFF3B82F6));
    }
    if (bmi < 25) return (label: 'Healthy', color: AppColors.accent);
    if (bmi < 30) return (label: 'Overweight', color: const Color(0xFFF59E0B));
    return (label: 'Obese', color: AppColors.error);
  }

  void _openCheckIn() {
    if (_profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DailyCheckInScreen(profile: _profile!)),
    );
  }

  void _openScheduleEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bmi = _profile?.bmi;
    final bmiInfo = bmi != null ? _bmiCategory(bmi) : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branded header
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

                // Greeting
                Text(
                  '$_greetingTime, $_greetingName 👋',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Let's crush today's goals.",
                  style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 22),

                // Quick-start CTA — premium gradient hero card
                _QuickStartCard(
                    goal: _profile?.fitnessGoal, onTap: widget.onStartWorkout),
                const SizedBox(height: 14),

                // Daily Check-In — drives the Dynamic Workout Engine
                _CheckInCard(
                  onCheckIn: _openCheckIn,
                  onEditSchedule: _openScheduleEditor,
                ),
                const SizedBox(height: 26),

                // Stat cards grid
                Text(
                  'Your Stats',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    DashboardStatCard(
                      icon: Icons.monitor_weight_outlined,
                      label: bmiInfo != null ? 'BMI · ${bmiInfo.label}' : 'BMI',
                      value: bmi != null ? bmi.toStringAsFixed(1) : '--',
                      color: bmiInfo?.color ?? AppColors.primary,
                    ),
                    DashboardStatCard(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Day Streak',
                      value: '$_streak',
                      color: const Color(0xFFF59E0B),
                    ),
                    DashboardStatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Workouts This Week',
                      value: '$_workoutsThisWeek',
                      color: AppColors.accent,
                    ),
                    DashboardStatCard(
                      icon: Icons.scale_outlined,
                      label: 'Current Weight',
                      value: _profile != null
                          ? '${_profile!.weightKg.toStringAsFixed(0)} kg'
                          : '--',
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Habit tracker glance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Habits",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onViewHabits,
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.surfaceBorder, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      HabitProgressRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Water Intake',
                        valueText:
                            '${_todayHabits?.waterGlasses ?? 0} / ${HabitGoals.waterGlasses} glasses',
                        progress: ((_todayHabits?.waterGlasses ?? 0) /
                                HabitGoals.waterGlasses)
                            .clamp(0.0, 1.0),
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 18),
                      HabitProgressRow(
                        icon: Icons.bedtime_outlined,
                        label: 'Sleep',
                        valueText:
                            '${(_todayHabits?.sleepHours ?? 0).toStringAsFixed(1)} / ${HabitGoals.sleepHours.toStringAsFixed(0)} hrs',
                        progress: ((_todayHabits?.sleepHours ?? 0) /
                                HabitGoals.sleepHours)
                            .clamp(0.0, 1.0),
                        color: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 18),
                      HabitProgressRow(
                        icon: Icons.egg_alt_outlined,
                        label: 'Protein',
                        valueText:
                            '${_todayHabits?.proteinGrams ?? 0} / ${HabitGoals.proteinGrams} g',
                        progress: ((_todayHabits?.proteinGrams ?? 0) /
                                HabitGoals.proteinGrams)
                            .clamp(0.0, 1.0),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium gradient hero card with decorative background rings —
/// the main "Start Workout" call to action on the dashboard.
class _QuickStartCard extends StatelessWidget {
  final String? goal;
  final VoidCallback? onTap;

  const _QuickStartCard({this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative rings for visual depth
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12), width: 18),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: -50,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (goal ?? 'TODAY').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Ready to train?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your next session is waiting',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'Start Workout',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily Check-In card — the entry point into the Dynamic Workout Engine.
/// Matches the surface/border/shadow styling already used by the habit
/// tracker card below it. A small calendar icon in the corner jumps to the
/// weekly schedule editor instead, so both new screens are reachable from
/// one place without touching the bottom nav.
class _CheckInCard extends StatelessWidget {
  final VoidCallback onCheckIn;
  final VoidCallback onEditSchedule;

  const _CheckInCard({required this.onCheckIn, required this.onEditSchedule});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCheckIn,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.self_improvement_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Check-In',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tell us how you feel to adapt today's plan",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit weekly schedule',
              onPressed: onEditSchedule,
              icon: const Icon(Icons.calendar_month_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
