import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_log.dart';

/// Handles Firestore reads/writes for daily habit tracking, stored at
/// `users/{uid}/habits/{yyyy-MM-dd}`.
class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('habits');
  }

  String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<HabitLog> getTodayLog() async {
    final today = formatDate(DateTime.now());
    final collection = _collection;
    if (collection == null) return HabitLog.empty(today);

    final doc = await collection.doc(today).get();
    if (!doc.exists || doc.data() == null) return HabitLog.empty(today);
    return HabitLog.fromMap(today, doc.data()!);
  }

  Future<void> saveLog(HabitLog log) async {
    final collection = _collection;
    if (collection == null) return;
    await collection.doc(log.date).set(log.toMap(), SetOptions(merge: true));
  }

  /// Fetches the last 7 days of logs (including today) for the
  /// weekly consistency strip. Missing days come back as empty logs.
  Future<List<HabitLog>> getLastSevenDays() async {
    final collection = _collection;
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    if (collection == null) {
      return days.map((d) => HabitLog.empty(formatDate(d))).toList();
    }

    final dateStrings = days.map(formatDate).toList();
    final snapshot = await collection
        .where(FieldPath.documentId, whereIn: dateStrings)
        .get();

    final byDate = {for (final doc in snapshot.docs) doc.id: doc.data()};

    return dateStrings.map((dateStr) {
      final data = byDate[dateStr];
      return data != null
          ? HabitLog.fromMap(dateStr, data)
          : HabitLog.empty(dateStr);
    }).toList();
  }
}
