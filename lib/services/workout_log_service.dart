import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_log.dart';

/// Handles all Firestore reads/writes for completed workouts, stored
/// at `users/{uid}/workoutLogs/{logId}`. Also computes the Day Streak
/// and Workouts This Week stats shown on the Home Dashboard.
class WorkoutLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('workoutLogs');
  }

  Future<void> saveWorkout(WorkoutLog log) async {
    final collection = _collection;
    if (collection == null) return;
    await collection.add(log.toMap());
  }

  Future<List<WorkoutLog>> getHistory({int limit = 30}) async {
    final collection = _collection;
    if (collection == null) return [];
    final snapshot =
        await collection.orderBy('date', descending: true).limit(limit).get();
    return snapshot.docs
        .map((d) => WorkoutLog.fromMap(d.id, d.data()))
        .toList();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Number of workouts logged since the most recent Monday.
  Future<int> getWorkoutsThisWeek() async {
    final logs = await getHistory(limit: 100);
    final now = DateTime.now();
    final startOfWeek =
        _dateOnly(now).subtract(Duration(days: now.weekday - 1));
    return logs
        .where((log) => !_dateOnly(log.date).isBefore(startOfWeek))
        .length;
  }

  /// Current consecutive-day streak, counting backward from today
  /// (or yesterday, if today doesn't have a workout logged yet).
  Future<int> getCurrentStreak() async {
    final logs = await getHistory(limit: 100);
    if (logs.isEmpty) return 0;

    final loggedDays = logs.map((log) => _dateOnly(log.date)).toSet();
    DateTime cursor = _dateOnly(DateTime.now());

    if (!loggedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!loggedDays.contains(cursor)) return 0;
    }

    int streak = 0;
    while (loggedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
