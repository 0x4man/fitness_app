/// Daily targets used across the Habit Tracker and Home Dashboard.
class HabitGoals {
  static const int waterGlasses = 8;
  static const double sleepHours = 8;
  static const int proteinGrams = 120;
  static const int caloriesKcal = 2000;
  static const int carbsGrams = 250;
  static const int fatGrams = 70;
}

/// One day's habit tracking, stored at `users/{uid}/habits/{yyyy-MM-dd}`
/// — one document per calendar day.
class HabitLog {
  final String date; // 'yyyy-MM-dd'
  final int waterGlasses;
  final double sleepHours;
  final int proteinGrams;
  final int caloriesKcal;
  final int carbsGrams;
  final int fatGrams;

  HabitLog({
    required this.date,
    this.waterGlasses = 0,
    this.sleepHours = 0,
    this.proteinGrams = 0,
    this.caloriesKcal = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
  });

  /// True if all four core habits met their daily goal — used for the
  /// weekly consistency strip.
  bool get isFullyComplete =>
      waterGlasses >= HabitGoals.waterGlasses &&
      sleepHours >= HabitGoals.sleepHours &&
      proteinGrams >= HabitGoals.proteinGrams &&
      caloriesKcal >= HabitGoals.caloriesKcal;

  HabitLog copyWith({
    int? waterGlasses,
    double? sleepHours,
    int? proteinGrams,
    int? caloriesKcal,
    int? carbsGrams,
    int? fatGrams,
  }) {
    return HabitLog(
      date: date,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      sleepHours: sleepHours ?? this.sleepHours,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }

  Map<String, dynamic> toMap() => {
        'waterGlasses': waterGlasses,
        'sleepHours': sleepHours,
        'proteinGrams': proteinGrams,
        'caloriesKcal': caloriesKcal,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
      };

  factory HabitLog.fromMap(String date, Map<String, dynamic> map) {
    return HabitLog(
      date: date,
      waterGlasses: (map['waterGlasses'] ?? 0) as int,
      sleepHours: (map['sleepHours'] ?? 0).toDouble(),
      proteinGrams: (map['proteinGrams'] ?? 0) as int,
      caloriesKcal: (map['caloriesKcal'] ?? 0) as int,
      carbsGrams: (map['carbsGrams'] ?? 0) as int,
      fatGrams: (map['fatGrams'] ?? 0) as int,
    );
  }

  factory HabitLog.empty(String date) => HabitLog(date: date);
}
