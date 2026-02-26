import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';
import '../../../shared/models/member.dart';
import '../../../shared/models/stokvel.dart';

class GroupService {
  final FirestoreService _db = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createStokvel({
    required String name,
    required String type,
    required double contributionAmount,
    required String contributionFrequency,
    required String createdBy,
    String? description,
  }) async {
    final ref = await _db.create('stokvels', {
      'name': name,
      'type': type,
      'contributionAmount': contributionAmount,
      'contributionFrequency': contributionFrequency,
      'currency': 'ZAR',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 1,
      'totalCollected': 0,
      'nasasaRegistered': false,
      'description': description,
    });
    return ref.id;
  }

  Future<void> addMember({
    required String stokvelId,
    required String userId,
    required String displayName,
    required String phone,
    MemberRole role = MemberRole.member,
    int? rotationOrder,
  }) async {
    await _db.set('stokvels/$stokvelId/members/$userId', {
      'userId': userId,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'rotationOrder': rotationOrder,
      'joinedAt': FieldValue.serverTimestamp(),
      'status': MemberStatus.active.name,
    });

    // Update member count
    await _firestore.doc('stokvels/$stokvelId').update({
      'memberCount': FieldValue.increment(1),
    });

    // Add stokvel to user's list
    await _firestore.doc('users/$userId').update({
      'stokvels': FieldValue.arrayUnion([stokvelId]),
    });
  }

  Future<void> removeMember(String stokvelId, String userId) async {
    await _db.delete('stokvels/$stokvelId/members/$userId');
    await _firestore.doc('stokvels/$stokvelId').update({
      'memberCount': FieldValue.increment(-1),
    });
    await _firestore.doc('users/$userId').update({
      'stokvels': FieldValue.arrayRemove([stokvelId]),
    });
  }

  Future<void> updateStokvel(
      String stokvelId, Map<String, dynamic> data) async {
    await _db.update('stokvels/$stokvelId', data);
  }

  Stream<List<Stokvel>> getUserStokvels(List<String> stokvelIds) {
    if (stokvelIds.isEmpty) {
      return Stream.value([]);
    }
    // Firestore 'in' queries support max 30 items
    final ids = stokvelIds.take(30).toList();
    return _firestore
        .collection('stokvels')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Stokvel.fromJson(d.data(), d.id)).toList());
  }

  Stream<Stokvel?> streamStokvel(String stokvelId) {
    return _db.streamDocument('stokvels/$stokvelId').map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Stokvel.fromJson(snap.data()!, snap.id);
    });
  }

  Stream<List<StokvelMember>> streamMembers(String stokvelId) {
    return _firestore
        .collection('stokvels/$stokvelId/members')
        .orderBy('role')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StokvelMember.fromJson(d.data(), d.id))
            .toList());
  }
}
