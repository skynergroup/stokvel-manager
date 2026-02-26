import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/meeting.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Schedule a new meeting.
  Future<String> scheduleMeeting({
    required String stokvelId,
    required String title,
    required DateTime date,
    required String createdBy,
    String? locationName,
    double? locationLat,
    double? locationLng,
    String? virtualLink,
    String? agenda,
  }) async {
    final ref =
        await _firestore.collection('stokvels/$stokvelId/meetings').add({
      'title': title,
      'date': Timestamp.fromDate(date),
      'locationName': locationName,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'virtualLink': virtualLink,
      'agenda': agenda,
      'minutes': null,
      'rsvps': <String, String>{},
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream all meetings for a stokvel, ordered by date (newest first).
  Stream<List<Meeting>> getMeetings(String stokvelId) {
    return _firestore
        .collection('stokvels/$stokvelId/meetings')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Meeting.fromJson(d.data(), d.id)).toList());
  }

  /// Update a user's RSVP for a meeting.
  Future<void> updateRsvp({
    required String stokvelId,
    required String meetingId,
    required String userId,
    required String response,
  }) async {
    await _firestore
        .doc('stokvels/$stokvelId/meetings/$meetingId')
        .update({'rsvps.$userId': response});
  }

  /// Record minutes for a meeting.
  Future<void> recordMinutes({
    required String stokvelId,
    required String meetingId,
    required String minutes,
  }) async {
    await _firestore
        .doc('stokvels/$stokvelId/meetings/$meetingId')
        .update({'minutes': minutes});
  }

  /// Get upcoming meetings for a user across all their groups.
  Future<List<({String stokvelId, String stokvelName, Meeting meeting})>>
      getUpcomingMeetings(List<String> stokvelIds) async {
    final now = DateTime.now();
    final results =
        <({String stokvelId, String stokvelName, Meeting meeting})>[];

    for (final stokvelId in stokvelIds) {
      final groupSnap = await _firestore.doc('stokvels/$stokvelId').get();
      final groupName =
          groupSnap.data()?['name'] as String? ?? 'Unknown Group';

      final snap = await _firestore
          .collection('stokvels/$stokvelId/meetings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date')
          .get();

      for (final doc in snap.docs) {
        results.add((
          stokvelId: stokvelId,
          stokvelName: groupName,
          meeting: Meeting.fromJson(doc.data(), doc.id),
        ));
      }
    }

    results.sort((a, b) => a.meeting.date.compareTo(b.meeting.date));
    return results;
  }

  /// Delete a meeting.
  Future<void> deleteMeeting({
    required String stokvelId,
    required String meetingId,
  }) async {
    await _firestore
        .doc('stokvels/$stokvelId/meetings/$meetingId')
        .delete();
  }

  /// Stream a single meeting document.
  Stream<Meeting?> streamMeeting(String stokvelId, String meetingId) {
    return _firestore
        .doc('stokvels/$stokvelId/meetings/$meetingId')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Meeting.fromJson(snap.data()!, snap.id);
    });
  }
}
