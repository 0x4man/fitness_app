import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// About FitTrack — branding, version, and a short description of
/// what the app does.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.heroGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                          text: 'Fit',
                          style: TextStyle(color: AppColors.textPrimary)),
                      TextSpan(
                          text: 'Track',
                          style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Text(
              'FitTrack is your all-in-one fitness companion — plan and log '
              'workouts, track daily habits like water, sleep, and protein, '
              'monitor your weight and BMI over time, and get nudged (in a '
              'fun way) to stay consistent. Built to help you show up for '
              'yourself, one day at a time.',
              style: TextStyle(
                  fontSize: 13.5, height: 1.6, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Built with', value: 'Flutter & Firebase'),
          _InfoRow(label: 'AI Coach powered by', value: 'Google Gemini'),
          _InfoRow(label: 'Made for', value: 'People who show up 💪'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
