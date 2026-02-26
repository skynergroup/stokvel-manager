import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../../shared/models/contribution.dart';
import '../../../shared/models/member.dart';

class ContributionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Record a new contribution for a member.
  Future<String> recordContribution({
    required String stokvelId,
    required String memberId,
    required String memberName,
    required double amount,
    required String recordedBy,
    DateTime? paidDate,
    String? proofUrl,
    String? notes,
  }) async {
    final ref = await _firestore
        .collection('stokvels/$stokvelId/contributions')
        .add({
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'dueDate': Timestamp.fromDate(paidDate ?? DateTime.now()),
      'paidDate': Timestamp.fromDate(paidDate ?? DateTime.now()),
      'proofUrl': proofUrl,
      'status': ContributionStatus.paid.firestoreValue,
      'recordedBy': recordedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'notes': notes,
    });

    // Update group's totalCollected
    await _firestore.doc('stokvels/$stokvelId').update({
      'totalCollected': FieldValue.increment(amount),
    });

    return ref.id;
  }

  /// Stream all contributions for a stokvel, ordered by creation date (newest first).
  Stream<List<Contribution>> getContributions(String stokvelId) {
    return _firestore
        .collection('stokvels/$stokvelId/contributions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Contribution.fromJson(d.data(), d.id))
            .toList());
  }

  /// Stream contributions for a specific member within a stokvel.
  Stream<List<Contribution>> getContributionsByMember(
    String stokvelId,
    String memberId,
  ) {
    return _firestore
        .collection('stokvels/$stokvelId/contributions')
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Contribution.fromJson(d.data(), d.id))
            .toList());
  }

  /// Get contribution status for all members for a given month.
  /// Returns a map of memberId -> ContributionStatus.
  Future<Map<String, ContributionStatus>> getMemberContributionStatus(
    String stokvelId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snap = await _firestore
        .collection('stokvels/$stokvelId/contributions')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final statusMap = <String, ContributionStatus>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final memberId = data['memberId'] as String;
      final status = ContributionStatus.fromFirestore(data['status'] as String);
      statusMap[memberId] = status;
    }
    return statusMap;
  }

  /// Generate pending contribution entries for all active members for the current month.
  Future<void> generateMonthlyContributions(String stokvelId) async {
    final now = DateTime.now();
    final dueDate = DateTime(now.year, now.month + 1, 0); // Last day of month

    // Get group info for contribution amount
    final groupSnap = await _firestore.doc('stokvels/$stokvelId').get();
    if (!groupSnap.exists) return;
    final groupData = groupSnap.data()!;
    final amount = (groupData['contributionAmount'] as num).toDouble();

    // Get active members
    final membersSnap = await _firestore
        .collection('stokvels/$stokvelId/members')
        .where('status', isEqualTo: MemberStatus.active.name)
        .get();

    // Check which members already have entries for this month
    final existingStatus = await getMemberContributionStatus(stokvelId, now);

    final batch = _firestore.batch();
    for (final memberDoc in membersSnap.docs) {
      final memberData = memberDoc.data();
      final memberId = memberDoc.id;

      // Skip if they already have an entry this month
      if (existingStatus.containsKey(memberId)) continue;

      final contribRef = _firestore
          .collection('stokvels/$stokvelId/contributions')
          .doc();
      batch.set(contribRef, {
        'memberId': memberId,
        'memberName': memberData['displayName'] as String,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'paidDate': null,
        'proofUrl': null,
        'status': ContributionStatus.pending.firestoreValue,
        'recordedBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'notes': null,
      });
    }
    await batch.commit();
  }

  /// Update a contribution's status and optionally its proof URL.
  Future<void> updateContributionStatus({
    required String stokvelId,
    required String contribId,
    required ContributionStatus status,
    String? proofUrl,
    double? amount,
  }) async {
    final data = <String, dynamic>{
      'status': status.firestoreValue,
    };
    if (proofUrl != null) data['proofUrl'] = proofUrl;

    if (status == ContributionStatus.paid) {
      data['paidDate'] = Timestamp.fromDate(DateTime.now());

      // Update totalCollected if marking as paid
      if (amount != null) {
        await _firestore.doc('stokvels/$stokvelId').update({
          'totalCollected': FieldValue.increment(amount),
        });
      }
    }

    await _firestore
        .doc('stokvels/$stokvelId/contributions/$contribId')
        .update(data);
  }

  /// Get total group balance: total collected from all paid contributions.
  Stream<double> getGroupBalance(String stokvelId) {
    return _firestore
        .collection('stokvels/$stokvelId/contributions')
        .where('status', isEqualTo: ContributionStatus.paid.firestoreValue)
        .snapshots()
        .map((snap) {
      double total = 0;
      for (final doc in snap.docs) {
        total += (doc.data()['amount'] as num).toDouble();
      }
      return total;
    });
  }

  /// Upload proof of payment image to Firebase Storage.
  /// Returns the download URL.
  Future<String> uploadProof({
    required String stokvelId,
    required String contribId,
    required File imageFile,
  }) async {
    final ext = imageFile.path.split('.').last;
    final ref = _storage.ref('stokvels/$stokvelId/proofs/$contribId.$ext');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  /// Stream a single contribution document.
  Stream<Contribution?> streamContribution(
    String stokvelId,
    String contribId,
  ) {
    return _firestore
        .doc('stokvels/$stokvelId/contributions/$contribId')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Contribution.fromJson(snap.data()!, snap.id);
    });
  }
}
