import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// TEMPORARY placeholder shown right after login/signup.
/// This will be replaced by the real Home Dashboard page next.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? user?.email ?? 'Athlete'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Home Dashboard coming in the next step.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => AuthService().signOut(),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
