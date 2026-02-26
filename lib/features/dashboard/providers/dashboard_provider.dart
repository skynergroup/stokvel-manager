import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return const DashboardData(
    userName: 'Thabo',
    totalSavings: 12400,
    groupCount: 2,
    nextContributionAmount: 500,
    nextContributionDays: 3,
    nextContributionGroup: 'Umoja Savings',
    nextPayoutAmount: 6000,
    nextPayoutGroup: 'Umoja Savings',
    nextMeetingDate: 'Sat 1 Mar, 10:00',
    nextMeetingLocation: "Mam' Nkosi's",
    recentActivity: [
      ActivityItem(description: 'Nomsa paid R500', timeAgo: '2h'),
      ActivityItem(description: 'Meeting scheduled', timeAgo: '12h'),
      ActivityItem(description: 'Sipho paid R500', timeAgo: '1d'),
    ],
  );
});
