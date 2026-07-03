import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/selectable_chip.dart';
import 'main_navigation_screen.dart';

const List<String> _genders = ['Male', 'Female', 'Other'];

const List<Map<String, dynamic>> _goals = [
  {'label': 'Lose Weight', 'icon': Icons.local_fire_department_outlined},
  {'label': 'Build Muscle', 'icon': Icons.fitness_center_outlined},
  {'label': 'Improve Endurance', 'icon': Icons.directions_run_outlined},
  {'label': 'Stay Fit', 'icon': Icons.favorite_outline},
];

/// Shown once, right after signup (or on login if the profile was
/// never completed). Collects fitness details and writes them to
/// Firestore via ProfileService, then routes to the Home Dashboard.
/// Also reused for "Edit Profile" from the Profile tab — in that case
/// existing values are pre-filled and Save just pops back instead of
/// navigating to the Home Dashboard.
class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;

  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _profileService = ProfileService();

  String? _selectedGender;
  String? _selectedGoal;
  bool _isLoading = false;
  bool _isFetchingExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isFetchingExisting = true);
    final profile = await _profileService.getProfile();
    if (profile != null && mounted) {
      _ageController.text = profile.age.toString();
      _heightController.text = profile.heightCm.toStringAsFixed(0);
      _weightController.text = profile.weightKg.toStringAsFixed(0);
      _selectedGender = profile.gender;
      _selectedGoal = profile.fitnessGoal;
    }
    if (mounted) setState(() => _isFetchingExisting = false);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      showAppMessage(context, 'Please select your gender.');
      return;
    }
    if (_selectedGoal == null) {
      showAppMessage(context, 'Please select your fitness goal.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = UserProfile(
        age: int.parse(_ageController.text.trim()),
        heightCm: double.parse(_heightController.text.trim()),
        weightKg: double.parse(_weightController.text.trim()),
        gender: _selectedGender!,
        fitnessGoal: _selectedGoal!,
      );
      await _profileService.saveProfile(profile);

      if (!mounted) return;
      if (widget.isEditing) {
        showAppMessage(context, 'Profile updated.', isError: false);
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Could not save profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isEditing)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing ? 'Edit Profile' : 'Tell Us About You',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps us personalize your workout plan.',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Age / Height / Weight
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Age',
                        hint: '25',
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0 || n > 120) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Height (cm)',
                        hint: '170',
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0 || n > 300) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Weight (kg)',
                  hint: '65',
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 400) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gender
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _genders.map((g) {
                    return SelectableChip(
                      label: g,
                      isSelected: _selectedGender == g,
                      onTap: () => setState(() => _selectedGender = g),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Fitness Goal
                const Text(
                  'Fitness Goal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _goals.map((g) {
                    return SelectableChip(
                      label: g['label'] as String,
                      icon: g['icon'] as IconData,
                      isSelected: _selectedGoal == g['label'],
                      onTap: () =>
                          setState(() => _selectedGoal = g['label'] as String),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                CustomButton(
                  text: widget.isEditing ? 'Save Changes' : 'Save & Continue',
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
