import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/user_profile.dart';
import 'firestore_service.dart';

class UserService {
  final FirestoreService _db = FirestoreService();

  Future<void> createProfile(UserProfile profile) {
    return _db.set('users/${profile.uid}', profile.toJson());
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _db.update('users/$uid', data);
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _db.streamDocument('users/$uid').map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromJson(snap.data()!, snap.id);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await FirebaseFirestore.instance.doc('users/$uid').get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromJson(snap.data()!, snap.id);
  }

  Future<void> updateFcmToken(String uid, String token) {
    return _db.update('users/$uid', {
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> updateSettings(
      String uid, Map<String, dynamic> settings) {
    return _db.update('users/$uid', {'settings': settings});
  }
}
