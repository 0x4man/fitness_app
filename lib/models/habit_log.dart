/// Daily targets used across the Habit Tracker and Home Dashboard.
class HabitGoals {
  static const int waterGlasses = 8;
  static const double sleepHours = 8;
  static const int proteinGrams = 120;
}

/// One day's habit tracking, stored at `users/{uid}/habits/{yyyy-MM-dd}`
/// — one document per calendar day.
class HabitLog {
  final String date; // 'yyyy-MM-dd'
  final int waterGlasses;
  final double sleepHours;
  final int proteinGrams;

  HabitLog({
    required this.date,
    this.waterGlasses = 0,
    this.sleepHours = 0,
    this.proteinGrams = 0,
  });

  /// True if all three habits met their daily goal — used for the
  /// weekly consistency strip.
  bool get isFullyComplete =>
      waterGlasses >= HabitGoals.waterGlasses &&
      sleepHours >= HabitGoals.sleepHours &&
      proteinGrams >= HabitGoals.proteinGrams;

  HabitLog copyWith(
      {int? waterGlasses, double? sleepHours, int? proteinGrams}) {
    return HabitLog(
      date: date,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      sleepHours: sleepHours ?? this.sleepHours,
      proteinGrams: proteinGrams ?? this.proteinGrams,
    );
  }

  Map<String, dynamic> toMap() => {
        'waterGlasses': waterGlasses,
        'sleepHours': sleepHours,
        'proteinGrams': proteinGrams,
      };

  factory HabitLog.fromMap(String date, Map<String, dynamic> map) {
    return HabitLog(
      date: date,
      waterGlasses: (map['waterGlasses'] ?? 0) as int,
      sleepHours: (map['sleepHours'] ?? 0).toDouble(),
      proteinGrams: (map['proteinGrams'] ?? 0) as int,
    );
  }

  factory HabitLog.empty(String date) => HabitLog(date: date);
}
