import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/meeting.dart';
import '../../groups/providers/groups_provider.dart';
import '../services/meeting_service.dart';

/// Service instance provider.
final meetingServiceProvider =
    Provider<MeetingService>((ref) => MeetingService());

/// Stream all meetings for a group.
final groupMeetingsProvider =
    StreamProvider.family<List<Meeting>, String>((ref, stokvelId) {
  return ref.watch(meetingServiceProvider).getMeetings(stokvelId);
});

/// Stream a single meeting.
final meetingDetailProvider = StreamProvider.family<Meeting?,
    ({String stokvelId, String meetingId})>((ref, params) {
  return ref
      .watch(meetingServiceProvider)
      .streamMeeting(params.stokvelId, params.meetingId);
});

/// Upcoming meetings across all user's groups.
final upcomingMeetingsProvider = FutureProvider<
    List<({String stokvelId, String stokvelName, Meeting meeting})>>(
    (ref) async {
  final stokvels = ref.watch(userStokvelsProvider).valueOrNull ?? [];
  if (stokvels.isEmpty) return [];

  final stokvelIds = stokvels.map((s) => s.id).toList();
  return ref
      .watch(meetingServiceProvider)
      .getUpcomingMeetings(stokvelIds);
});

/// Notifier for scheduling a meeting.
class ScheduleMeetingNotifier extends StateNotifier<AsyncValue<void>> {
  final MeetingService _service;

  ScheduleMeetingNotifier(this._service)
      : super(const AsyncValue.data(null));

  Future<bool> schedule({
    required String stokvelId,
    required String title,
    required DateTime date,
    required String createdBy,
    String? locationName,
    String? virtualLink,
    String? agenda,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.scheduleMeeting(
        stokvelId: stokvelId,
        title: title,
        date: date,
        createdBy: createdBy,
        locationName: locationName,
        virtualLink: virtualLink,
        agenda: agenda,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final scheduleMeetingProvider =
    StateNotifierProvider<ScheduleMeetingNotifier, AsyncValue<void>>((ref) {
  return ScheduleMeetingNotifier(ref.watch(meetingServiceProvider));
});

/// Notifier for updating RSVP.
class RsvpNotifier extends StateNotifier<AsyncValue<void>> {
  final MeetingService _service;

  RsvpNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> updateRsvp({
    required String stokvelId,
    required String meetingId,
    required String userId,
    required String response,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateRsvp(
        stokvelId: stokvelId,
        meetingId: meetingId,
        userId: userId,
        response: response,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final rsvpProvider =
    StateNotifierProvider<RsvpNotifier, AsyncValue<void>>((ref) {
  return RsvpNotifier(ref.watch(meetingServiceProvider));
});
