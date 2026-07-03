import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'habits/habit_tracker_screen.dart';
import 'home/home_dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'progress/progress_dashboard_screen.dart';
import 'workouts/workout_library_screen.dart';

/// The main app shell after login/profile-setup. Hosts the bottom
/// navigation bar with 5 tabs. Home, Workouts, and Profile are fully
/// built — Habits and Progress show a "Coming Soon" placeholder until
/// we build them in later steps.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeDashboardScreen(
        onStartWorkout: () => setState(() => _currentIndex = 1),
        onViewHabits: () => setState(() => _currentIndex = 2),
      ),
      const WorkoutLibraryScreen(),
      const HabitTrackerScreen(),
      const ProgressDashboardScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          elevation: 0,
          height: 66,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon:
                  Icon(Icons.fitness_center_rounded, color: AppColors.primary),
              label: 'Workouts',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon:
                  Icon(Icons.checklist_rounded, color: AppColors.primary),
              label: 'Habits',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon:
                  Icon(Icons.insights_rounded, color: AppColors.primary),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
