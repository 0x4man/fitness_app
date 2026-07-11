/// Represents the fitness profile data collected right after signup.
/// Stored as fields on the `users/{uid}` Firestore document.
///
/// Extended from the original with five fields the Dynamic Workout Engine
/// needs: experienceLevel, injuries, availableEquipment,
/// workoutFrequencyPerWeek, preferredDurationMinutes. All have defaults, so
/// this is a drop-in replacement — ProfileSetupScreen's existing
/// `UserProfile(name: ..., age: ..., ...)` call still compiles unchanged.
/// You'll want a "Training preferences" step somewhere to actually collect
/// the new fields from the user.
class UserProfile {
  final String name;
  final int age;
  final double heightCm;
  final double weightKg;
  final String gender; // 'Male' | 'Female' | 'Other'
  final String
      fitnessGoal; // 'Lose Weight' | 'Build Muscle' | 'Improve Endurance' | 'Stay Fit'

  // --- New fields for the Dynamic Workout Engine -----------------------
  /// 'Beginner' | 'Intermediate' | 'Advanced' — matches Exercise.difficulty
  /// so the engine can filter/substitute using the same vocabulary already
  /// used in the exercise catalog.
  final String experienceLevel;

  /// Free-text injury notes, e.g. "left knee", "lower back". Matched by
  /// keyword against Exercise.muscleGroup values in the decision engine.
  final List<String> injuries;

  /// Equipment the user has access to, matching Exercise.equipment values
  /// (e.g. "Bodyweight", "Dumbbell", "Barbell", "Machine", "Kettlebell").
  final List<String> availableEquipment;

  final int workoutFrequencyPerWeek;
  final int preferredDurationMinutes;

  const UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.fitnessGoal,
    this.experienceLevel = 'Beginner',
    this.injuries = const [],
    this.availableEquipment = const [],
    this.workoutFrequencyPerWeek = 3,
    this.preferredDurationMinutes = 45,
  });

  /// Body Mass Index, calculated from height/weight.
  double get bmi {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender,
      'fitnessGoal': fitnessGoal,
      'experienceLevel': experienceLevel,
      'injuries': injuries,
      'availableEquipment': availableEquipment,
      'workoutFrequencyPerWeek': workoutFrequencyPerWeek,
      'preferredDurationMinutes': preferredDurationMinutes,
      'profileComplete': true,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      age: (map['age'] ?? 0) as int,
      heightCm: (map['heightCm'] ?? 0).toDouble(),
      weightKg: (map['weightKg'] ?? 0).toDouble(),
      gender: map['gender'] ?? '',
      fitnessGoal: map['fitnessGoal'] ?? '',
      experienceLevel: map['experienceLevel'] ?? 'Beginner',
      injuries: List<String>.from(map['injuries'] ?? []),
      availableEquipment: List<String>.from(map['availableEquipment'] ?? []),
      workoutFrequencyPerWeek: (map['workoutFrequencyPerWeek'] ?? 3) as int,
      preferredDurationMinutes: (map['preferredDurationMinutes'] ?? 45) as int,
    );
  }

  static const Map<String, List<String>> _injuryKeywordsByMuscleGroup = {
    'legs': ['knee', 'hamstring', 'quad', 'ankle', 'hip'],
    'back': ['back', 'spine', 'disc'],
    'shoulders': ['shoulder', 'rotator cuff'],
    'chest': ['chest', 'pec'],
    'arms': ['elbow', 'wrist', 'bicep', 'tricep'],
    'core': ['core', 'abdominal', 'hernia'],
  };

  /// Returns true if any logged injury keyword matches the given muscle
  /// group (matching Exercise.muscleGroup values like "Legs", "Back").
  bool hasInjuryAffecting(String muscleGroup) {
    final keywords = _injuryKeywordsByMuscleGroup[muscleGroup.toLowerCase()];
    if (keywords == null || keywords.isEmpty) return false;
    return injuries
        .any((injury) => keywords.any((k) => injury.toLowerCase().contains(k)));
  }

  bool hasEquipment(String equipment) => availableEquipment
      .map((e) => e.toLowerCase())
      .contains(equipment.toLowerCase());
}
