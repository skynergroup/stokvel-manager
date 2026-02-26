import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM, HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Upcoming Meetings',
            style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        _MeetingCard(
          title: 'March Monthly Meeting',
          dateStr: dateFormat.format(DateTime(2026, 3, 1, 10, 0)),
          location: "Mam' Nkosi's house",
          isVirtual: false,
          yesCount: 8,
          noCount: 2,
          maybeCount: 1,
          groupName: 'Umoja Savings',
        ),
        _MeetingCard(
          title: 'Emergency Meeting',
          dateStr: dateFormat.format(DateTime(2026, 3, 5, 18, 0)),
          location: 'Google Meet',
          isVirtual: true,
          yesCount: 15,
          noCount: 5,
          maybeCount: 3,
          groupName: 'Kasi Burial Society',
        ),
        const Gap(24),
        Text('Past Meetings', style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('February Monthly Meeting',
                  style: Theme.of(context).textTheme.titleSmall),
              const Gap(4),
              Text(
                dateFormat.format(DateTime(2026, 2, 1, 10, 0)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text('Umoja Savings',
                  style: Theme.of(context).textTheme.bodySmall),
              const Gap(4),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 16),
                  const Gap(4),
                  Text('10 attended',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ],
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

  const _MeetingCard({
    required this.title,
    required this.dateStr,
    required this.location,
    required this.isVirtual,
    required this.yesCount,
    required this.noCount,
    required this.maybeCount,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                  isVirtual ? Icons.videocam_outlined : Icons.location_on_outlined,
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
              const Icon(Icons.schedule, size: 16,
                  color: AppColors.textSecondaryLight),
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
              Text(location, style: Theme.of(context).textTheme.bodySmall),
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
                  label: 'Maybe', count: maybeCount, color: AppColors.warning),
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
