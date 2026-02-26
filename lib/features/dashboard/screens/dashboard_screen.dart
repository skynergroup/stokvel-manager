import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../groups/providers/groups_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardData = ref.watch(dashboardDataProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.pushNamed(RouteNames.notifications),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userStokvelsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_greeting(l10n)}, ${dashboardData.userName}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Gap(16),

            // Total Savings
            AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalSavings,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          currencyFormat.format(dashboardData.totalSavings),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          l10n.acrossGroups(dashboardData.groupCount),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),

            // Next Contribution
            if (dashboardData.nextContributionGroup.isNotEmpty)
              AppCard(
                onTap: () => context.pushNamed(RouteNames.groups),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondary,
                        size: 28,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.nextContribution,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            l10n.dueInDays(
                              currencyFormat.format(dashboardData.nextContributionAmount),
                              dashboardData.nextContributionDays,
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            dashboardData.nextContributionGroup,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondaryLight),
                  ],
                ),
              ),
            if (dashboardData.nextContributionGroup.isNotEmpty) const Gap(8),

            // Next Payout
            if (dashboardData.nextPayoutGroup.isNotEmpty)
              AppCard(
                onTap: () => context.pushNamed(RouteNames.groups),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up_outlined,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.nextPayout,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            currencyFormat
                                .format(dashboardData.nextPayoutAmount),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.accent),
                          ),
                          Text(
                            dashboardData.nextPayoutGroup,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondaryLight),
                  ],
                ),
              ),
            if (dashboardData.nextPayoutGroup.isNotEmpty) const Gap(8),

            // Next Meeting
            AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.info,
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nextMeeting,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          dashboardData.nextMeetingDate,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (dashboardData.nextMeetingLocation.isNotEmpty)
                          Text(
                            dashboardData.nextMeetingLocation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Recent Activity
            if (dashboardData.recentActivity.isNotEmpty) ...[
              Text(
                l10n.recentActivity,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Gap(8),
              ...dashboardData.recentActivity.map(
                (activity) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          activity.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        activity.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Empty state when no groups
            if (dashboardData.groupCount == 0) ...[
              const Gap(32),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: AppColors.textSecondaryLight,
                    ),
                    const Gap(16),
                    Text(
                      l10n.joinOrCreate,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
