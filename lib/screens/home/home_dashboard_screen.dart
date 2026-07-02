import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_stat_card.dart';

/// The main Home tab: greeting, BMI (calculated from the user's saved
/// profile), a placeholder streak/today's-workout summary, and a
/// quick-start CTA. Workout/habit data will populate the placeholder
/// cards once the Workout Tracker and Habit Tracker are built.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _profileService = ProfileService();
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
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
    if (bmi < 18.5)
      return (label: 'Underweight', color: const Color(0xFF3B82F6));
    if (bmi < 25) return (label: 'Healthy', color: AppColors.accent);
    if (bmi < 30) return (label: 'Overweight', color: const Color(0xFFF59E0B));
    return (label: 'Obese', color: AppColors.error);
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
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  _greetingTime,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _greetingName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Quick-start CTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ready to train?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _profile?.fitnessGoal ??
                                  'Start your first workout',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Will open Workout Library in a later step.
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size(140, 42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Start Workout',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white24,
                        size: 64,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stat cards grid
                Text(
                  'Your Stats',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withOpacity(0.8),
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
                    const DashboardStatCard(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Day Streak',
                      value: '0',
                      color: Color(0xFFF59E0B),
                    ),
                    const DashboardStatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Workouts This Week',
                      value: '0',
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
                const SizedBox(height: 24),

                // Habit tracker glance
                Text(
                  "Today's Habits",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      _HabitRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Water Intake',
                          value: '0 / 8 glasses'),
                      Divider(height: 24),
                      _HabitRow(
                          icon: Icons.bedtime_outlined,
                          label: 'Sleep',
                          value: '0 / 8 hrs'),
                      Divider(height: 24),
                      _HabitRow(
                          icon: Icons.egg_alt_outlined,
                          label: 'Protein',
                          value: '0 / 120 g'),
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

class _HabitRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HabitRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
