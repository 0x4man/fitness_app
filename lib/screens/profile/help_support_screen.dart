import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// Help & Support — a short FAQ covering the app's core features,
/// plus a "Contact Support" button that opens the user's email app
/// with a pre-filled subject.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      q: 'How do I log a workout?',
      a: 'Go to the Workouts tab, tap any exercise, then "Add to Today\'s '
          'Workout". Once you\'ve added your exercises, tap the "Start '
          'Workout" bar at the bottom to log sets, reps, and weight.',
    ),
    (
      q: 'How is my BMI calculated?',
      a: 'BMI uses your most recent logged weight (or your profile weight '
          'if you haven\'t logged one yet) and your height from your '
          'profile: weight (kg) ÷ height (m)².',
    ),
    (
      q: 'How do I track my weight over time?',
      a: 'Open the Progress tab and tap "Log Weight" at the top of the '
          'Weight Trend card. Log on at least 2 different days to see '
          'your trend line.',
    ),
    (
      q: 'What do the daily habit goals mean?',
      a: 'Water, sleep, and protein each have a default daily goal '
          '(8 glasses, 8 hours, 120g). Log your progress from the '
          'Habits tab throughout the day.',
    ),
    (
      q: 'Can I turn off daily reminders?',
      a: 'Yes — go to Profile → Daily Reminders and toggle it off. This '
          'cancels all scheduled workout, water, and sleep notifications.',
    ),
    (
      q: 'Is my data private?',
      a: 'Your workouts, habits, and profile are stored securely in your '
          'own account and are not visible to other users.',
    ),
  ];

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@fittrack.app',
      query: 'subject=${Uri.encodeComponent('FitTrack Support Request')}',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => _FaqTile(question: faq.q, answer: faq.a)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send us an email and we\'ll get back to you.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _contactSupport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact Support'),
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

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              answer,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
