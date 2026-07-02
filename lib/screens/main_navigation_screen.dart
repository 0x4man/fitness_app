import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'coming_soon_screen.dart';
import 'home/home_dashboard_screen.dart';

/// The main app shell after login/profile-setup. Hosts the bottom
/// navigation bar with 5 tabs. Only Home is fully built right now —
/// Workouts, Habits, and Progress show a "Coming Soon" placeholder
/// until we build them in later steps. Profile lets the user log out.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeDashboardScreen(),
    ComingSoonScreen(title: 'Workouts', icon: Icons.fitness_center_rounded),
    ComingSoonScreen(title: 'Habits', icon: Icons.checklist_rounded),
    ComingSoonScreen(title: 'Progress', icon: Icons.insights_rounded),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
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
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Minimal Profile tab for now — just shows the user's email and a
/// logout button. Will be expanded into a full Profile/Settings page.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Athlete',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Log Out',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
