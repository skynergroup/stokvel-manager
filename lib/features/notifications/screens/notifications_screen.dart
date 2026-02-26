import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notification data
    final notifications = [
      _NotificationGroup(
        label: 'Today',
        items: [
          _NotificationItem(
            title: 'Nomsa paid R500',
            subtitle: 'Umoja Savings \u00b7 2h',
            isRead: false,
            icon: Icons.payments_outlined,
            color: AppColors.success,
          ),
          _NotificationItem(
            title: 'Meeting scheduled',
            subtitle: 'Kasi Burial Society \u00b7 5h',
            isRead: false,
            icon: Icons.calendar_today_outlined,
            color: AppColors.info,
          ),
        ],
      ),
      _NotificationGroup(
        label: 'Yesterday',
        items: [
          _NotificationItem(
            title: 'Contribution due',
            subtitle: 'R500 \u00b7 Umoja Savings \u00b7 1d',
            isRead: true,
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
          ),
          _NotificationItem(
            title: 'Sipho paid R500',
            subtitle: 'Umoja Savings \u00b7 1d',
            isRead: true,
            icon: Icons.payments_outlined,
            color: AppColors.success,
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: const BackButton(),
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: "You're all caught up!",
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, groupIndex) {
                final group = notifications[groupIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupIndex > 0) const Gap(16),
                    Text(
                      group.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const Gap(8),
                    ...group.items.map((item) => Dismissible(
                          key: ValueKey('${group.label}_${item.title}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: AppColors.error,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item.icon,
                                    color: item.color, size: 20),
                              ),
                              title: Row(
                                children: [
                                  if (!item.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: item.isRead
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(item.subtitle),
                              onTap: () {
                                // TODO: Navigate to relevant screen
                              },
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
    );
  }
}

class _NotificationGroup {
  final String label;
  final List<_NotificationItem> items;

  const _NotificationGroup({required this.label, required this.items});
}

class _NotificationItem {
  final String title;
  final String subtitle;
  final bool isRead;
  final IconData icon;
  final Color color;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.isRead,
    required this.icon,
    required this.color,
  });
}
