import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dynamic_workout_models.dart';

/// Handles reads/writes for daily health check-ins, stored at
/// `users/{uid}/dailyCheckIns/{yyyy-MM-dd}`. Keyed by date (not an
/// auto-id, unlike WorkoutLogService) so re-submitting today's check-in
/// overwrites rather than duplicates.
class DailyHealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('dailyCheckIns');
  }

  String _docIdFor(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> saveCheckIn(DailyHealthInput input) async {
    final collection = _collection;
    if (collection == null) return;
    await collection.doc(_docIdFor(input.date)).set(input.toMap());
  }

  Future<DailyHealthInput?> getCheckInFor(DateTime date) async {
    final collection = _collection;
    if (collection == null) return null;
    final doc = await collection.doc(_docIdFor(date)).get();
    if (!doc.exists || doc.data() == null) return null;
    return DailyHealthInput.fromMap(doc.data()!);
  }

  Future<DailyHealthInput?> getTodayCheckIn() => getCheckInFor(DateTime.now());

  Future<bool> hasCheckedInToday() async => (await getTodayCheckIn()) != null;

  Future<List<DailyHealthInput>> getHistory({int limit = 30}) async {
    final collection = _collection;
    if (collection == null) return [];
    final snapshot =
        await collection.orderBy('date', descending: true).limit(limit).get();
    return snapshot.docs
        .map((d) => DailyHealthInput.fromMap(d.data()))
        .toList();
  }
}
