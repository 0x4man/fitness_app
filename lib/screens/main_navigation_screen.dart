import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat/ai_chat_screen.dart';
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

  static const _destinations = [
    _NavItem(
        icon: Icons.home_rounded,
        outlineIcon: Icons.home_outlined,
        label: 'Home'),
    _NavItem(
        icon: Icons.fitness_center_rounded,
        outlineIcon: Icons.fitness_center_outlined,
        label: 'Workouts'),
    _NavItem(
        icon: Icons.task_alt_rounded,
        outlineIcon: Icons.task_alt_outlined,
        label: 'Habits'),
    _NavItem(
        icon: Icons.auto_graph_rounded,
        outlineIcon: Icons.show_chart_rounded,
        label: 'Progress'),
    _NavItem(
        icon: Icons.person_rounded,
        outlineIcon: Icons.person_outline_rounded,
        label: 'Profile'),
  ];

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
        ),
      ),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _currentIndex,
        destinations: _destinations,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlineIcon;
  final String label;

  const _NavItem(
      {required this.icon, required this.outlineIcon, required this.label});
}

/// A custom bottom nav bar with a gradient pill behind the selected tab,
/// replacing the default flat Material NavigationBar for a more premium,
/// branded look consistent with the hero-gradient cards used elsewhere
/// in the app (Daily Check-In card, progress rings, etc).
class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> destinations;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({
    required this.currentIndex,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: AppColors.heroGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isSelected ? item.icon : item.outlineIcon,
                          size: 22,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
