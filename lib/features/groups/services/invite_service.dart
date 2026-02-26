import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';

class InviteService {
  final FirestoreService _db = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> createInvite({
    required String stokvelId,
    required String createdBy,
    Duration expiry = const Duration(days: 7),
  }) async {
    final code = _generateCode();
    await _db.set('invites/$code', {
      'stokvelId': stokvelId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(expiry)),
    });
    return code;
  }

  Future<Map<String, dynamic>?> validateInvite(String code) async {
    final snap = await _firestore.doc('invites/$code').get();
    if (!snap.exists || snap.data() == null) return null;

    final data = snap.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (expiresAt.isBefore(DateTime.now())) {
      // Expired — clean up
      await _firestore.doc('invites/$code').delete();
      return null;
    }
    return data;
  }

  Future<void> deleteInvite(String code) {
    return _db.delete('invites/$code');
  }

  String getInviteLink(String code) {
    return 'stokvelmanager.app/join/$code';
  }
}
