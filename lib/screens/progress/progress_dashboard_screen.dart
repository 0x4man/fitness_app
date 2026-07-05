import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import '../../services/profile_service.dart';
import '../../services/weight_log_service.dart';
import '../../services/workout_log_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_snackbar.dart';
import '../profile/profile_screen.dart';

/// Progress Dashboard — BMI, weight trend line chart, workout
/// consistency bar chart, and a week-over-week comparison. Pulls from
/// ProfileService, WeightLogService, and WorkoutLogService.
class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _profileService = ProfileService();
  final _weightLogService = WeightLogService();
  final _workoutLogService = WorkoutLogService();

  UserProfile? _profile;
  List<WeightLog> _weightHistory = [];
  List<MapEntry<DateTime, int>> _dailySets = [];
  int _thisWeekWorkouts = 0;
  int _lastWeekWorkouts = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _profileService.getProfile(),
        _weightLogService.getHistory(limit: 14),
        _workoutLogService.getDailySetsLastNDays(7),
        _workoutLogService.getWeekOverWeekWorkouts(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfile?;
          _weightHistory = results[1] as List<WeightLog>;
          _dailySets = results[2] as List<MapEntry<DateTime, int>>;
          final weekPair = results[3] as (int, int);
          _thisWeekWorkouts = weekPair.$1;
          _lastWeekWorkouts = weekPair.$2;
          _isLoading = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('ProgressDashboard load error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load progress data.\n($e)';
          _isLoading = false;
        });
      }
    }
  }

  double? get _currentWeight {
    if (_weightHistory.isNotEmpty) return _weightHistory.last.weightKg;
    return _profile?.weightKg;
  }

  double? get _currentBmi {
    final weight = _currentWeight;
    final height = _profile?.heightCm;
    if (weight == null || height == null) return null;
    final heightM = height / 100;
    return weight / (heightM * heightM);
  }

  ({String label, Color color}) _bmiCategory(double bmi) {
    if (bmi < 18.5) return (label: 'Underweight', color: const Color(0xFF3B82F6));
    if (bmi < 25) return (label: 'Healthy', color: AppColors.accent);
    if (bmi < 30) return (label: 'Overweight', color: const Color(0xFFF59E0B));
    return (label: 'Obese', color: AppColors.error);
  }

  Future<void> _showLogWeightDialog() async {
    final controller = TextEditingController(
      text: _currentWeight != null ? _currentWeight!.toStringAsFixed(1) : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Today\'s Weight', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: const InputDecoration(
            suffixText: 'kg',
            suffixStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await _weightLogService.logWeight(DateTime.now(), result);
      if (mounted) {
        showAppMessage(context, 'Weight logged: ${result.toStringAsFixed(1)} kg', isError: false);
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final bmi = _currentBmi;
    final bmiInfo = bmi != null ? _bmiCategory(bmi) : null;
    final weekChange = _thisWeekWorkouts - _lastWeekWorkouts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
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
              const SizedBox(height: 18),
              const Text(
                'Your Progress',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Track how far you\'ve come.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 20),

              // BMI hero card
              _BmiCard(bmi: bmi, category: bmiInfo),
              const SizedBox(height: 16),

              // Week-over-week comparison
              Row(
                children: [
                  Expanded(
                    child: _ComparisonCard(
                      label: 'This Week',
                      value: '$_thisWeekWorkouts',
                      sublabel: 'workouts',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ComparisonCard(
                      label: 'vs Last Week',
                      value: weekChange == 0 ? '±0' : (weekChange > 0 ? '+$weekChange' : '$weekChange'),
                      sublabel: weekChange >= 0 ? 'more consistent' : 'less than before',
                      valueColor: weekChange >= 0 ? AppColors.accent : AppColors.error,
                      icon: weekChange >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weight trend chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weight Trend',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: _showLogWeightDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text(
                            'Log Weight',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _WeightTrendCard(history: _weightHistory),
              const SizedBox(height: 24),

              // Workout consistency chart
              const Text(
                'Workout Consistency',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Total sets logged per day, last 7 days',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 12),
              _ConsistencyChartCard(dailySets: _dailySets),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double? bmi;
  final ({String label, Color color})? category;

  const _BmiCard({required this.bmi, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BODY MASS INDEX',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bmi != null ? bmi!.toStringAsFixed(1) : '--',
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: 1),
                ),
                const SizedBox(height: 8),
                if (category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category!.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          _BmiRing(bmi: bmi),
        ],
      ),
    );
  }
}

/// A simple circular gauge showing where the BMI falls on the
/// 15–35 scale, drawn with CustomPaint (no extra dependency needed
/// for a single ring).
class _BmiRing extends StatelessWidget {
  final double? bmi;

  const _BmiRing({required this.bmi});

  @override
  Widget build(BuildContext context) {
    final progress = bmi == null ? 0.0 : ((bmi! - 15) / (35 - 15)).clamp(0.0, 1.0);
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              backgroundColor: Colors.transparent,
            ),
          ),
          const Icon(Icons.monitor_weight_rounded, color: Colors.white, size: 26),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color? valueColor;
  final IconData? icon;

  const _ComparisonCard({
    required this.label,
    required this.value,
    required this.sublabel,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 18, color: valueColor),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  final List<WeightLog> history;

  const _WeightTrendCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: history.length < 2
          ? Center(
              child: Text(
                'Log your weight on at least 2 days\nto see your trend.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary.withValues(alpha: 0.85)),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _yInterval,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.surfaceBorder, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: _yInterval,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (history.length / 4).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) return const SizedBox.shrink();
                        final date = history[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                minY: _minY,
                maxY: _maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      history.length,
                      (i) => FlSpot(i.toDouble(), history[i].weightKg),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.primary.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double get _minValue => history.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
  double get _maxValue => history.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  double get _minY => (_minValue - 2).floorToDouble();
  double get _maxY => (_maxValue + 2).ceilToDouble();
  double get _yInterval => ((_maxY - _minY) / 4).clamp(1, double.infinity);
}

class _ConsistencyChartCard extends StatelessWidget {
  final List<MapEntry<DateTime, int>> dailySets;

  const _ConsistencyChartCard({required this.dailySets});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxSets = dailySets.isEmpty
        ? 1
        : dailySets.map((e) => e.value).reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxSets * 1.3),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailySets.length) return const SizedBox.shrink();
                  final isToday = index == dailySets.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dayLabels[dailySets[index].key.weekday - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(dailySets.length, (i) {
            final entry = dailySets[i];
            final isToday = i == dailySets.length - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: entry.value > 0 ? (isToday ? AppColors.accent : AppColors.primary) : AppColors.surfaceBorder,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}