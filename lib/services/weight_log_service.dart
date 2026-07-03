import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weight_log.dart';

/// Handles Firestore reads/writes for weight tracking, stored at
/// `users/{uid}/weightLogs/{yyyy-MM-dd}`. Powers the weight trend
/// chart and current-weight/BMI on the Progress Dashboard.
class WeightLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('weightLogs');
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> logWeight(DateTime date, double weightKg) async {
    final collection = _collection;
    if (collection == null) return;
    await collection.doc(_formatDate(date)).set(
        WeightLog(date: date, weightKg: weightKg).toMap(),
        SetOptions(merge: true));
  }

  /// Most recent entries, oldest first — ready to feed directly into a
  /// line chart.
  Future<List<WeightLog>> getHistory({int limit = 30}) async {
    final collection = _collection;
    if (collection == null) return [];
    final snapshot = await collection
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .get();
    final logs = snapshot.docs.map((d) {
      final parts = d.id.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return WeightLog.fromMap(date, d.data());
    }).toList();
    return logs.reversed.toList();
  }

  Future<WeightLog?> getLatest() async {
    final history = await getHistory(limit: 1);
    return history.isEmpty ? null : history.last;
  }
}
