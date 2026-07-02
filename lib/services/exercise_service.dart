import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

/// Handles reads for the global exercise library (`exercises`
/// collection) and auto-seeds a starter set of common exercises the
/// first time the app runs against a fresh Firestore project — so
/// there's no manual console data entry required to get started.
class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Exercise>> getExercises() async {
    await _seedIfEmpty();
    final snapshot =
        await _firestore.collection('exercises').orderBy('name').get();
    return snapshot.docs.map((d) => Exercise.fromMap(d.id, d.data())).toList();
  }

  Future<void> _seedIfEmpty() async {
    final existing = await _firestore.collection('exercises').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final exercise in _starterExercises) {
      final doc = _firestore.collection('exercises').doc();
      batch.set(doc, exercise.toMap());
    }
    await batch.commit();
  }

  static final List<Exercise> _starterExercises = [
    Exercise(
      id: '',
      name: 'Push-Up',
      muscleGroup: 'Chest',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 15,
      instructions: [
        'Start in a plank position with hands shoulder-width apart.',
        'Lower your body until your chest nearly touches the floor.',
        'Push back up to the starting position.',
        'Keep your core tight throughout the movement.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      defaultSets: 4,
      defaultReps: 10,
      instructions: [
        'Lie on a flat bench with feet flat on the floor.',
        'Grip the bar slightly wider than shoulder-width.',
        'Lower the bar to your mid-chest with control.',
        'Press the bar back up until arms are fully extended.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Pull-Up',
      muscleGroup: 'Back',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      defaultSets: 3,
      defaultReps: 8,
      instructions: [
        'Hang from the bar with an overhand grip, hands shoulder-width apart.',
        'Pull your body up until your chin clears the bar.',
        'Lower back down with control to a full hang.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Bent-Over Row',
      muscleGroup: 'Back',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Hinge at the hips, keeping your back flat.',
        'Pull the dumbbells toward your waist, squeezing shoulder blades.',
        'Lower with control back to the starting position.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Deadlift',
      muscleGroup: 'Back',
      equipment: 'Barbell',
      difficulty: 'Advanced',
      defaultSets: 4,
      defaultReps: 6,
      instructions: [
        'Stand with feet hip-width apart, bar over mid-foot.',
        'Hinge down and grip the bar just outside your legs.',
        'Drive through your heels, keeping the bar close to your body.',
        'Stand tall, then lower the bar back down with control.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Squat',
      muscleGroup: 'Legs',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      defaultSets: 4,
      defaultReps: 10,
      instructions: [
        'Stand with feet shoulder-width apart, bar on your upper back.',
        'Lower your hips down and back, keeping your chest up.',
        'Descend until thighs are at least parallel to the floor.',
        'Drive back up through your heels to standing.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Bodyweight Lunge',
      muscleGroup: 'Legs',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Step forward with one leg, lowering your hips.',
        'Bend both knees to about 90 degrees.',
        'Push back to the starting position and switch legs.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Leg Press',
      muscleGroup: 'Legs',
      equipment: 'Machine',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Sit in the leg press machine with feet shoulder-width on the platform.',
        'Lower the platform by bending your knees toward your chest.',
        'Press back up without locking your knees fully.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Overhead Press',
      muscleGroup: 'Shoulders',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      defaultSets: 3,
      defaultReps: 10,
      instructions: [
        'Stand with the bar at shoulder height, grip just outside shoulders.',
        'Press the bar straight overhead until arms are locked out.',
        'Lower back down to shoulder height with control.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Lateral Raise',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 15,
      instructions: [
        'Hold a dumbbell in each hand at your sides.',
        'Raise both arms out to the sides until shoulder height.',
        'Lower back down with control.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Bicep Curl',
      muscleGroup: 'Arms',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Hold dumbbells at your sides, palms facing forward.',
        'Curl the weights up toward your shoulders.',
        'Lower back down slowly with control.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Tricep Dip',
      muscleGroup: 'Arms',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Support your body on parallel bars or a bench, arms straight.',
        'Lower your body by bending your elbows to about 90 degrees.',
        'Push back up to the starting position.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Plank',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 1,
      instructions: [
        'Rest on your forearms and toes, body in a straight line.',
        'Keep your core braced and hips level — avoid sagging.',
        'Hold for 30-60 seconds per set.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Russian Twist',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 20,
      instructions: [
        'Sit with knees bent, lean back slightly, feet off the floor.',
        'Rotate your torso side to side, tapping the floor each time.',
        'Keep your core engaged throughout.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Hanging Leg Raise',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      difficulty: 'Advanced',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Hang from a pull-up bar with arms fully extended.',
        'Raise your legs until they are parallel to the floor.',
        'Lower back down with control, avoiding swinging.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Burpee',
      muscleGroup: 'Full Body',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      defaultSets: 3,
      defaultReps: 12,
      instructions: [
        'Drop into a squat and place hands on the floor.',
        'Kick your feet back into a plank, then do a push-up.',
        'Jump feet back to your hands, then jump straight up.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Kettlebell Swing',
      muscleGroup: 'Full Body',
      equipment: 'Kettlebell',
      difficulty: 'Intermediate',
      defaultSets: 3,
      defaultReps: 15,
      instructions: [
        'Stand with feet shoulder-width apart, kettlebell in front.',
        'Hinge at the hips and swing the kettlebell between your legs.',
        'Drive your hips forward to swing the bell to chest height.',
      ],
    ),
    Exercise(
      id: '',
      name: 'Mountain Climbers',
      muscleGroup: 'Full Body',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      defaultSets: 3,
      defaultReps: 20,
      instructions: [
        'Start in a plank position.',
        'Drive one knee toward your chest, then switch quickly.',
        'Keep your hips low and core engaged throughout.',
      ],
    ),
  ];
}
