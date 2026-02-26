import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/contribution.dart';
import '../../../shared/models/stokvel.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/contribution_provider.dart';

class ContributionsScreen extends ConsumerWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userContribsAsync = ref.watch(allUserContributionsProvider);

    return userContribsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (groupContribs) {
        if (groupContribs.isEmpty) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No contributions yet',
            message: 'Join a group to start tracking contributions.',
          );
        }

        // Split into upcoming (pending/late) and history (paid) across all groups
        final upcoming = <({Stokvel group, Contribution contribution})>[];
        final history = <({Stokvel group, Contribution contribution})>[];

        for (final gc in groupContribs) {
          for (final c in gc.contributions) {
            final item = (group: gc.group, contribution: c);
            if (c.status == ContributionStatus.paid) {
              history.add(item);
            } else {
              upcoming.add(item);
            }
          }
        }

        // Sort upcoming by due date (soonest first)
        upcoming.sort(
            (a, b) => a.contribution.dueDate.compareTo(b.contribution.dueDate));
        // Sort history by paid date (newest first)
        history.sort((a, b) {
          final aDate = a.contribution.paidDate ?? a.contribution.createdAt;
          final bDate = b.contribution.paidDate ?? b.contribution.createdAt;
          return bDate.compareTo(aDate);
        });

        // Group history by month for aggregation
        final historyByMonth =
            <String, List<({Stokvel group, Contribution contribution})>>{};
        for (final item in history) {
          final date = item.contribution.paidDate ?? item.contribution.createdAt;
          final key = DateFormat('MMM yyyy').format(date);
          historyByMonth.putIfAbsent(key, () => []).add(item);
        }

        // Build groups with no pending (already paid this month)
        final upcomingGroupIds = upcoming.map((e) => e.group.id).toSet();
        final paidGroups = <({Stokvel group, Contribution contribution})>[];
        for (final gc in groupContribs) {
          if (!upcomingGroupIds.contains(gc.group.id)) {
            final now = DateTime.now();
            final paidThisMonth = gc.contributions.where((c) {
              return c.status == ContributionStatus.paid &&
                  c.paidDate != null &&
                  c.paidDate!.month == now.month &&
                  c.paidDate!.year == now.year;
            });
            if (paidThisMonth.isNotEmpty) {
              paidGroups.add(
                  (group: gc.group, contribution: paidThisMonth.first));
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Upcoming contributions
            if (upcoming.isNotEmpty || paidGroups.isNotEmpty) ...[
              Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              ...upcoming.map((item) => _ContributionCard(
                    group: item.group,
                    contribution: item.contribution,
                  )),
              ...paidGroups.map((item) => _ContributionCard(
                    group: item.group,
                    contribution: item.contribution,
                  )),
              const Gap(24),
            ],

            // History
            if (historyByMonth.isNotEmpty) ...[
              Text('History', style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              ...historyByMonth.entries.map((entry) {
                final totalAmount = entry.value.fold<double>(
                    0, (sum, item) => sum + item.contribution.amount);
                final groupCount =
                    entry.value.map((e) => e.group.id).toSet().length;
                return _HistoryRow(
                  month: entry.key,
                  amount: totalAmount,
                  groups: groupCount,
                );
              }),
            ],

            if (upcoming.isEmpty &&
                paidGroups.isEmpty &&
                historyByMonth.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No contributions yet',
                message:
                    'Your contributions will appear here once recorded.',
              ),
          ],
        );
      },
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Stokvel group;
  final Contribution contribution;

  const _ContributionCard({
    required this.group,
    required this.contribution,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM');

    Color statusColor;
    String statusText;

    switch (contribution.status) {
      case ContributionStatus.paid:
        statusColor = AppColors.success;
        statusText = 'Paid';
      case ContributionStatus.late_:
        statusColor = AppColors.error;
        statusText = 'Late';
      case ContributionStatus.excused:
        statusColor = AppColors.info;
        statusText = 'Excused';
      case ContributionStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Pending';
    }

    final dueLine = contribution.status == ContributionStatus.paid
        ? '${currencyFormat.format(contribution.amount)} this month'
        : '${currencyFormat.format(contribution.amount)} due ${dateFormat.format(contribution.dueDate)}';

    return AppCard(
      onTap: () => context.pushNamed(
        RouteNames.groupDetail,
        pathParameters: {'id': group.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: Theme.of(context).textTheme.titleSmall),
          const Gap(4),
          Row(
            children: [
              Expanded(
                child: Text(
                  dueLine,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String month;
  final double amount;
  final int groups;

  const _HistoryRow({
    required this.month,
    required this.amount,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Text(month, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '${currencyFormat.format(amount)} ($groups ${groups == 1 ? 'group' : 'groups'})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
