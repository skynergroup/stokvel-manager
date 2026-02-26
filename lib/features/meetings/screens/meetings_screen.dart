import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/meeting_provider.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(upcomingMeetingsProvider);
    final dateFormat = DateFormat('EEE d MMM, HH:mm');

    return meetingsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (meetings) {
        if (meetings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined,
                    size: 64, color: AppColors.textSecondaryLight),
                const Gap(16),
                Text(
                  'No upcoming meetings',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Upcoming Meetings',
                style: Theme.of(context).textTheme.titleLarge),
            const Gap(8),
            ...meetings.map((entry) => _MeetingCard(
                  title: entry.meeting.title,
                  dateStr: dateFormat.format(entry.meeting.date),
                  location: entry.meeting.isVirtual
                      ? (entry.meeting.virtualLink ?? 'Virtual')
                      : (entry.meeting.locationName ?? 'TBD'),
                  isVirtual: entry.meeting.isVirtual,
                  yesCount: entry.meeting.yesCount,
                  noCount: entry.meeting.noCount,
                  maybeCount: entry.meeting.maybeCount,
                  groupName: entry.stokvelName,
                  onTap: () => context.pushNamed(
                    RouteNames.meetingDetail,
                    pathParameters: {
                      'groupId': entry.stokvelId,
                      'meetingId': entry.meeting.id,
                    },
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final String title;
  final String dateStr;
  final String location;
  final bool isVirtual;
  final int yesCount;
  final int noCount;
  final int maybeCount;
  final String groupName;
  final VoidCallback? onTap;

  const _MeetingCard({
    required this.title,
    required this.dateStr,
    required this.location,
    required this.isVirtual,
    required this.yesCount,
    required this.noCount,
    required this.maybeCount,
    required this.groupName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVirtual
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(groupName,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 16, color: AppColors.textSecondaryLight),
              const Gap(4),
              Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Gap(4),
          Row(
            children: [
              Icon(
                isVirtual ? Icons.link : Icons.place,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
              const Gap(4),
              Expanded(
                child: Text(location,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              _RsvpBadge(
                  label: 'Yes', count: yesCount, color: AppColors.success),
              const Gap(8),
              _RsvpBadge(
                  label: 'No', count: noCount, color: AppColors.error),
              const Gap(8),
              _RsvpBadge(
                  label: 'Maybe',
                  count: maybeCount,
                  color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _RsvpBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RsvpBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
