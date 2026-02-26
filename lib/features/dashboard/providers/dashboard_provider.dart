import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../meetings/providers/meeting_provider.dart';
import '../../payouts/providers/payout_provider.dart';

class DashboardData {
  final String userName;
  final double totalSavings;
  final int groupCount;
  final double nextContributionAmount;
  final int nextContributionDays;
  final String nextContributionGroup;
  final double nextPayoutAmount;
  final String nextPayoutGroup;
  final String nextMeetingDate;
  final String nextMeetingLocation;
  final List<ActivityItem> recentActivity;

  const DashboardData({
    required this.userName,
    required this.totalSavings,
    required this.groupCount,
    required this.nextContributionAmount,
    required this.nextContributionDays,
    required this.nextContributionGroup,
    required this.nextPayoutAmount,
    required this.nextPayoutGroup,
    required this.nextMeetingDate,
    required this.nextMeetingLocation,
    required this.recentActivity,
  });
}

class ActivityItem {
  final String description;
  final String timeAgo;

  const ActivityItem({required this.description, required this.timeAgo});
}

final dashboardDataProvider = Provider<DashboardData>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final stokvels = ref.watch(userStokvelsProvider).valueOrNull ?? [];

  final userName = profile?.displayName.split(' ').first ?? 'there';
  final totalSavings =
      stokvels.fold<double>(0, (sum, s) => sum + s.totalCollected);
  final groupCount = stokvels.length;

  // Find next contribution (soonest due from any group)
  double nextAmount = 0;
  int nextDays = 0;
  String nextGroup = '';
  if (stokvels.isNotEmpty) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    nextDays = endOfMonth.difference(now).inDays;
    nextAmount = stokvels.first.contributionAmount;
    nextGroup = stokvels.first.name;
  }

  // Next payout from real data
  double nextPayoutAmount = 0;
  String nextPayoutGroup = '';
  final userPayouts = ref.watch(userPayoutsProvider).valueOrNull ?? [];
  if (userPayouts.isNotEmpty) {
    final scheduled = userPayouts.where(
        (p) => p.payout.status.name == 'scheduled' ||
            p.payout.status.name == 'approved');
    if (scheduled.isNotEmpty) {
      final next = scheduled.first;
      nextPayoutAmount = next.payout.amount;
      nextPayoutGroup = next.stokvelName;
    }
  }
  // Fallback to estimate if no real payouts
  if (nextPayoutGroup.isEmpty && stokvels.isNotEmpty) {
    nextPayoutAmount =
        stokvels.first.contributionAmount * stokvels.first.memberCount;
    nextPayoutGroup = stokvels.first.name;
  }

  // Next meeting from real data
  String nextMeetingDate = 'No meetings scheduled';
  String nextMeetingLocation = '';
  final upcomingMeetings =
      ref.watch(upcomingMeetingsProvider).valueOrNull ?? [];
  if (upcomingMeetings.isNotEmpty) {
    final next = upcomingMeetings.first;
    final dateFormat = DateFormat('EEE d MMM, HH:mm');
    nextMeetingDate = dateFormat.format(next.meeting.date);
    nextMeetingLocation = next.meeting.locationName ??
        (next.meeting.isVirtual ? 'Virtual' : '');
  }

  return DashboardData(
    userName: userName,
    totalSavings: totalSavings,
    groupCount: groupCount,
    nextContributionAmount: nextAmount,
    nextContributionDays: nextDays,
    nextContributionGroup: nextGroup,
    nextPayoutAmount: nextPayoutAmount,
    nextPayoutGroup: nextPayoutGroup,
    nextMeetingDate: nextMeetingDate,
    nextMeetingLocation: nextMeetingLocation,
    recentActivity: const [],
  );
});
