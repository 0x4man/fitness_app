import 'package:flutter/material.dart';
import '../../models/habit_log.dart';
import '../../services/habit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';

/// A quick-log food preset — tapping adds all four macro values at once.
class _FoodPreset {
  final String name;
  final IconData icon;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const _FoodPreset({
    required this.name,
    required this.icon,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

const List<_FoodPreset> _presets = [
  _FoodPreset(
      name: 'Rice',
      icon: Icons.rice_bowl_rounded,
      calories: 200,
      protein: 4,
      carbs: 45,
      fat: 0),
  _FoodPreset(
      name: 'Egg',
      icon: Icons.egg_rounded,
      calories: 78,
      protein: 6,
      carbs: 1,
      fat: 5),
  _FoodPreset(
      name: 'Roti',
      icon: Icons.bakery_dining_rounded,
      calories: 120,
      protein: 3,
      carbs: 18,
      fat: 3),
  _FoodPreset(
      name: 'Dal',
      icon: Icons.rice_bowl_rounded,
      calories: 230,
      protein: 18,
      carbs: 40,
      fat: 1),
  _FoodPreset(
      name: 'Paneer',
      icon: Icons.egg_alt_rounded,
      calories: 265,
      protein: 18,
      carbs: 1,
      fat: 20),
  _FoodPreset(
      name: 'Cheese',
      icon: Icons.restaurant_rounded,
      calories: 110,
      protein: 7,
      carbs: 1,
      fat: 9),
  _FoodPreset(
      name: 'Milk',
      icon: Icons.local_drink_rounded,
      calories: 150,
      protein: 8,
      carbs: 12,
      fat: 8),
  _FoodPreset(
      name: 'Chicken',
      icon: Icons.set_meal_rounded,
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 4),
  _FoodPreset(
      name: 'Banana',
      icon: Icons.eco_rounded,
      calories: 105,
      protein: 1,
      carbs: 27,
      fat: 0),
];

/// Nutrition sub-view, embedded inside the Habits tab behind a toggle so
/// the existing Daily Habits view stays completely untouched. Reuses
/// HabitService/HabitLog — nutrition data lives in the same per-day
/// document as water/sleep, just with the new carbsGrams/fatGrams fields.
class NutritionTrackerView extends StatefulWidget {
  const NutritionTrackerView({super.key});

  @override
  State<NutritionTrackerView> createState() => _NutritionTrackerViewState();
}

class _NutritionTrackerViewState extends State<NutritionTrackerView> {
  final _habitService = HabitService();
  HabitLog? _today;
  bool _isLoading = true;
  String? _errorMessage;

  // User's standing nutrition goals — loaded from Firestore in _load(),
  // defaulted here so the UI has something sensible to show immediately.
  int _calGoal = HabitGoals.caloriesKcal;
  int _proteinGoal = HabitGoals.proteinGrams;
  int _carbsGoal = HabitGoals.carbsGrams;
  int _fatGoal = HabitGoals.fatGrams;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final log = await _habitService.getTodayLog();
      final goals = await _habitService.getNutritionGoals();
      if (mounted) {
        setState(() {
          _today = log;
          _calGoal = goals['calories'] ?? HabitGoals.caloriesKcal;
          _proteinGoal = goals['protein'] ?? HabitGoals.proteinGrams;
          _carbsGoal = goals['carbs'] ?? HabitGoals.carbsGrams;
          _fatGoal = goals['fat'] ?? HabitGoals.fatGrams;
          _isLoading = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('NutritionTrackerView load error: $e');
      if (mounted)
        setState(() {
          _errorMessage = '$e';
          _isLoading = false;
        });
    }
  }

  Future<void> _addFood({
    String? name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    // Fetch the latest saved doc first — not the possibly-stale cached
    // _today — so this write never clobbers water/sleep that may have
    // just been changed from the Daily Habits tab.
    final latest = await _habitService.getTodayLog();
    final updated = latest.copyWith(
      caloriesKcal: latest.caloriesKcal + calories,
      proteinGrams: latest.proteinGrams + protein,
      carbsGrams: latest.carbsGrams + carbs,
      fatGrams: latest.fatGrams + fat,
    );
    setState(() => _today = updated);
    await _habitService.saveLog(updated);
    if (mounted) {
      final label =
          (name != null && name.trim().isNotEmpty) ? name.trim() : 'Food';
      showAppMessage(
        context,
        '$label added — ${calories}kcal · ${protein}p · ${carbs}c · ${fat}f',
        isError: false,
      );
    }
  }

  /// Sets a new standing GOAL for one macro (the right side of "1056 /
  /// 2000") — not today's logged amount. This is what lets someone on a
  /// high-calorie diet raise their target above the 2000kcal default,
  /// and it's persisted so it sticks across app restarts.
  Future<void> _setGoal(String macro, int newGoal) async {
    setState(() {
      switch (macro) {
        case 'calories':
          _calGoal = newGoal;
          break;
        case 'protein':
          _proteinGoal = newGoal;
          break;
        case 'carbs':
          _carbsGoal = newGoal;
          break;
        case 'fat':
          _fatGoal = newGoal;
          break;
      }
    });
    await _habitService.saveNutritionGoals({
      'calories': _calGoal,
      'protein': _proteinGoal,
      'carbs': _carbsGoal,
      'fat': _fatGoal,
    });
  }

  Future<void> _openEditGoalDialog({
    required String macroKey,
    required String label,
    required String unit,
    required int currentGoal,
  }) async {
    final controller = TextEditingController(text: currentGoal.toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Set $label Goal',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed != null && parsed > 0) {
                  _setGoal(macroKey, parsed);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddFoodDialog() async {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: const Text(
                'Log a Food',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogField(
                        label: 'Food name (optional)',
                        controller: nameController),
                    const SizedBox(height: 10),
                    _DialogField(
                        label: 'Calories (kcal)',
                        controller: calController,
                        isNumber: true),
                    const SizedBox(height: 10),
                    _DialogField(
                        label: 'Protein (g)',
                        controller: proteinController,
                        isNumber: true),
                    const SizedBox(height: 10),
                    _DialogField(
                        label: 'Carbs (g)',
                        controller: carbsController,
                        isNumber: true),
                    const SizedBox(height: 10),
                    _DialogField(
                        label: 'Fat (g)',
                        controller: fatController,
                        isNumber: true),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    final cal = int.tryParse(calController.text.trim()) ?? 0;
                    final protein =
                        int.tryParse(proteinController.text.trim()) ?? 0;
                    final carbs =
                        int.tryParse(carbsController.text.trim()) ?? 0;
                    final fat = int.tryParse(fatController.text.trim()) ?? 0;
                    if (cal == 0 && protein == 0 && carbs == 0 && fat == 0) {
                      setDialogState(() => errorText =
                          'Enter at least a calorie value to add this food.');
                      return;
                    }
                    _addFood(
                      name: nameController.text,
                      calories: cal,
                      protein: protein,
                      carbs: carbs,
                      fat: fat,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _buildInsights(HabitLog log) {
    final insights = <String>[];

    final calPercent = _calGoal > 0
        ? ((log.caloriesKcal / _calGoal) * 100).clamp(0, 999).round()
        : 0;
    final calRemaining = (_calGoal - log.caloriesKcal).clamp(0, _calGoal);
    insights.add(calRemaining > 0
        ? 'You\'ve reached $calPercent% of today\'s calorie target — ${calRemaining}kcal remaining.'
        : 'Calorie goal reached for today — well done.');

    final proteinRemaining = _proteinGoal - log.proteinGrams;
    insights.add(proteinRemaining > 0
        ? 'You\'re ${proteinRemaining}g short of your protein target — consider a high-protein snack.'
        : 'Protein goal complete — excellent consistency.');

    insights.add(
        'Add a serving of citrus or leafy greens to round out today\'s micronutrients.');

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null || _today == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                'Could not load nutrition data.\n${_errorMessage ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final today = _today!;
    final insights = _buildInsights(today);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          Text(
            'Nutrition',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Track what fuels your progress.',
            style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 18),

          // Macro rings — horizontally scrollable so nothing ever
          // overflows regardless of screen width.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _MacroRing(
                    label: 'Calories',
                    value: today.caloriesKcal,
                    goal: _calGoal,
                    unit: '',
                    color: const Color(0xFFF87171),
                    onTap: () => _openEditGoalDialog(
                      macroKey: 'calories',
                      label: 'Calories',
                      unit: 'kcal',
                      currentGoal: _calGoal,
                    ),
                  ),
                  const SizedBox(width: 18),
                  _MacroRing(
                    label: 'Protein',
                    value: today.proteinGrams,
                    goal: _proteinGoal,
                    unit: 'g',
                    color: const Color(0xFF84CC16),
                    onTap: () => _openEditGoalDialog(
                      macroKey: 'protein',
                      label: 'Protein',
                      unit: 'g',
                      currentGoal: _proteinGoal,
                    ),
                  ),
                  const SizedBox(width: 18),
                  _MacroRing(
                    label: 'Carbs',
                    value: today.carbsGrams,
                    goal: _carbsGoal,
                    unit: 'g',
                    color: const Color(0xFF60A5FA),
                    onTap: () => _openEditGoalDialog(
                      macroKey: 'carbs',
                      label: 'Carbs',
                      unit: 'g',
                      currentGoal: _carbsGoal,
                    ),
                  ),
                  const SizedBox(width: 18),
                  _MacroRing(
                    label: 'Fat',
                    value: today.fatGrams,
                    goal: _fatGoal,
                    unit: 'g',
                    color: const Color(0xFFFBBF24),
                    onTap: () => _openEditGoalDialog(
                      macroKey: 'fat',
                      label: 'Fat',
                      unit: 'g',
                      currentGoal: _fatGoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Smart Insights',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...insights.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InsightCard(text: text),
              )),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Log a Food',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: _openAddFoodDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.heroGradient),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final preset = _presets[i];
                return GestureDetector(
                  onTap: () => _addFood(
                    name: preset.name,
                    calories: preset.calories,
                    protein: preset.protein,
                    carbs: preset.carbs,
                    fat: preset.fat,
                  ),
                  child: Container(
                    width: 84,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(preset.icon, color: AppColors.accent, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          preset.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${preset.calories} kcal',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final String unit;
  final Color color;
  final VoidCallback? onTap;

  const _MacroRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Clamped to 0.999, not 1.0 — Flutter's CircularProgressIndicator has
    // a long-standing rendering quirk where an arc that closes at exactly
    // 100% can show a hairline seam/gap at the top from floating-point
    // precision in the arc sweep. Capping just short of full closes the
    // visible gap while looking identical to a complete ring.
    final progress =
        goal > 0 ? (value / goal).clamp(0.0, 0.999).toDouble() : 0.0;
    final percent = goal > 0 ? ((value / goal) * 100).clamp(0, 999).round() : 0;
    final isOverGoal = goal > 0 && value > goal;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // A single indicator draws both the background track and
                  // the progress arc together (via backgroundColor) — using
                  // two separately stacked CircularProgressIndicators was
                  // the actual cause of the "chopped at the top" artifact:
                  // two independently-drawn circles never align perfectly
                  // at their shared start point (12 o'clock), regardless
                  // of the percentage. One indicator can't misalign with
                  // itself.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => SizedBox(
                      width: 66,
                      height: 66,
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 6,
                        backgroundColor:
                            AppColors.surfaceBorder.withValues(alpha: 0.6),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  // Percentage — wrapped in a FittedBox so it always
                  // shrinks to fit no matter how many digits (100%,
                  // 300%, 999%), instead of guessing a font size.
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$value / $goal$unit',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isOverGoal
                    ? color
                    : AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;

  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isNumber;

  const _DialogField(
      {required this.label, required this.controller, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
