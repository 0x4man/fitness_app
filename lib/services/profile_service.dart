import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

/// Handles all Firestore reads/writes for the user's fitness profile
/// (age, height, weight, gender, goal). Profile fields live directly
/// on the `users/{uid}` document alongside name/email.
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Used by AuthGate right after login to decide whether to show
  /// the Profile Setup screen or go straight to the Home Dashboard.
  Future<bool> hasCompletedProfile() async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['profileComplete'] == true);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final uid = _uid;
    if (uid == null) throw Exception('No logged-in user.');
    await _firestore.collection('users').doc(uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
    // Keep Firebase Auth's displayName in sync so anywhere reading
    // currentUser.displayName (e.g. the Profile hero card) stays
    // consistent with the name saved here.
    await _auth.currentUser?.updateDisplayName(profile.name);
  }

  Future<UserProfile?> getProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
