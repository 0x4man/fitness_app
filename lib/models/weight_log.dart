/// A single weight entry, stored at `users/{uid}/weightLogs/{yyyy-MM-dd}`
/// — one entry per day (logging again the same day overwrites it).
class WeightLog {
  final DateTime date;
  final double weightKg;

  WeightLog({required this.date, required this.weightKg});

  Map<String, dynamic> toMap() => {'weightKg': weightKg};

  factory WeightLog.fromMap(DateTime date, Map<String, dynamic> map) {
    return WeightLog(date: date, weightKg: (map['weightKg'] ?? 0).toDouble());
  }
}
