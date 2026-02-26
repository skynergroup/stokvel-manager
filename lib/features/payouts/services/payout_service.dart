import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/member.dart';
import '../../../shared/models/payout.dart';

class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a full rotation schedule for a rotational stokvel.
  /// Creates one payout entry per active member based on their rotationOrder.
  Future<void> createRotationSchedule(String stokvelId) async {
    // Get group info
    final groupSnap = await _firestore.doc('stokvels/$stokvelId').get();
    if (!groupSnap.exists) return;
    final groupData = groupSnap.data()!;
    final amount = (groupData['contributionAmount'] as num).toDouble();
    final memberCount = groupData['memberCount'] as int? ?? 0;
    final totalPayout = amount * memberCount;

    // Get active members ordered by rotation
    final membersSnap = await _firestore
        .collection('stokvels/$stokvelId/members')
        .where('status', isEqualTo: MemberStatus.active.name)
        .orderBy('rotationOrder')
        .get();

    if (membersSnap.docs.isEmpty) return;

    // Clear existing scheduled payouts
    final existingSnap = await _firestore
        .collection('stokvels/$stokvelId/payouts')
        .where('status', isEqualTo: PayoutStatus.scheduled.name)
        .get();
    final batch = _firestore.batch();
    for (final doc in existingSnap.docs) {
      batch.delete(doc.reference);
    }

    // Create a payout for each member in rotation order
    final now = DateTime.now();
    for (var i = 0; i < membersSnap.docs.length; i++) {
      final memberData = membersSnap.docs[i].data();
      final payoutDate = DateTime(now.year, now.month + i + 1, 0);
      final ref =
          _firestore.collection('stokvels/$stokvelId/payouts').doc();
      batch.set(ref, {
        'recipientId': memberData['userId'] as String,
        'recipientName': memberData['displayName'] as String,
        'amount': totalPayout,
        'payoutDate': Timestamp.fromDate(payoutDate),
        'type': PayoutType.rotation.firestoreValue,
        'status': PayoutStatus.scheduled.name,
        'approvedBy': <String>[],
        'notes': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Stream all payouts for a stokvel, ordered by payout date.
  Stream<List<Payout>> getPayoutSchedule(String stokvelId) {
    return _firestore
        .collection('stokvels/$stokvelId/payouts')
        .orderBy('payoutDate')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Payout.fromJson(d.data(), d.id)).toList());
  }

  /// Request a new payout (creates with status 'scheduled').
  Future<String> requestPayout({
    required String stokvelId,
    required String recipientId,
    required String recipientName,
    required double amount,
    required PayoutType type,
    String? notes,
  }) async {
    final ref =
        await _firestore.collection('stokvels/$stokvelId/payouts').add({
      'recipientId': recipientId,
      'recipientName': recipientName,
      'amount': amount,
      'payoutDate': Timestamp.fromDate(DateTime.now()),
      'type': type.firestoreValue,
      'status': PayoutStatus.scheduled.name,
      'approvedBy': <String>[],
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Approve a payout — adds approverId to the approvedBy array.
  Future<void> approvePayout({
    required String stokvelId,
    required String payoutId,
    required String approverId,
  }) async {
    await _firestore.doc('stokvels/$stokvelId/payouts/$payoutId').update({
      'approvedBy': FieldValue.arrayUnion([approverId]),
      'status': PayoutStatus.approved.name,
    });
  }

  /// Mark a payout as paid.
  Future<void> markPayoutPaid({
    required String stokvelId,
    required String payoutId,
  }) async {
    await _firestore.doc('stokvels/$stokvelId/payouts/$payoutId').update({
      'status': PayoutStatus.paid.name,
    });
  }

  /// Get the next scheduled payout for a stokvel.
  Stream<Payout?> getNextPayout(String stokvelId) {
    return _firestore
        .collection('stokvels/$stokvelId/payouts')
        .where('status', isEqualTo: PayoutStatus.scheduled.name)
        .orderBy('payoutDate')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return Payout.fromJson(snap.docs.first.data(), snap.docs.first.id);
    });
  }

  /// Stream a single payout document.
  Stream<Payout?> streamPayout(String stokvelId, String payoutId) {
    return _firestore
        .doc('stokvels/$stokvelId/payouts/$payoutId')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Payout.fromJson(snap.data()!, snap.id);
    });
  }

  /// Get all upcoming payouts for a specific user across all their groups.
  Future<List<({String stokvelId, String stokvelName, Payout payout})>>
      getUserUpcomingPayouts(String userId, List<String> stokvelIds) async {
    final results =
        <({String stokvelId, String stokvelName, Payout payout})>[];

    for (final stokvelId in stokvelIds) {
      final groupSnap = await _firestore.doc('stokvels/$stokvelId').get();
      final groupName =
          groupSnap.data()?['name'] as String? ?? 'Unknown Group';

      final snap = await _firestore
          .collection('stokvels/$stokvelId/payouts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('payoutDate')
          .get();

      for (final doc in snap.docs) {
        results.add((
          stokvelId: stokvelId,
          stokvelName: groupName,
          payout: Payout.fromJson(doc.data(), doc.id),
        ));
      }
    }

    results.sort((a, b) => a.payout.payoutDate.compareTo(b.payout.payoutDate));
    return results;
  }
}
