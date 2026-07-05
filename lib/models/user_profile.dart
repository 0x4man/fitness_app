/// Represents the fitness profile data collected right after signup.
/// Stored as fields on the `users/{uid}` Firestore document.
class UserProfile {
  final String name;
  final int age;
  final double heightCm;
  final double weightKg;
  final String gender; // 'Male' | 'Female' | 'Other'
  final String
      fitnessGoal; // 'Lose Weight' | 'Build Muscle' | 'Improve Endurance' | 'Stay Fit'

  const UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.fitnessGoal,
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
    );
  }
}
