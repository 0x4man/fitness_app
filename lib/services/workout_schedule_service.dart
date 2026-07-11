import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../models/workout_schedule.dart';
import '../models/dynamic_workout_models.dart';

/// Handles reads/writes for the user's weekly workout schedule, stored as
/// a single document at `users/{uid}/settings/workoutSchedule` — unlike
/// WorkoutLogService/DailyHealthService, there's exactly one schedule per
/// user (not a growing history), so it's one doc, not a collection.
class WorkoutScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('workoutSchedule');
  }

  Future<WorkoutSchedule> getSchedule() async {
    final doc = _doc;
    if (doc == null) return WorkoutSchedule.empty();
    final snapshot = await doc.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return WorkoutSchedule.empty();
    }
    return WorkoutSchedule.fromMap(snapshot.data()!);
  }

  Future<void> saveSchedule(WorkoutSchedule schedule) async {
    final doc = _doc;
    if (doc == null) return;
    await doc.set(schedule.toMap());
  }

  Future<void> saveDay(ScheduledDay day) async {
    final current = await getSchedule();
    await saveSchedule(current.updateDay(day));
  }

  /// Returns today's scheduled plan hydrated against the live exercise
  /// catalog, or null if today is a rest day.
  Future<WorkoutPlan?> getTodaysPlan(List<Exercise> catalog) async {
    final schedule = await getSchedule();
    final today = schedule.forToday();
    if (today.isRestDay || today.exercises.isEmpty) return null;
    return today.toWorkoutPlan(catalog);
  }
}
