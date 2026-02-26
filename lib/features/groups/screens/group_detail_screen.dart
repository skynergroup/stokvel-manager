import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/contribution.dart';
import '../../../shared/models/member.dart';
import '../../../shared/models/payout.dart';
import '../../../shared/models/stokvel.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/stokvel_type_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contributions/providers/contribution_provider.dart';
import '../../payouts/providers/payout_provider.dart';
import '../providers/groups_provider.dart';
import '../services/invite_service.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(stokvelDetailProvider(widget.groupId));
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return groupAsync.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            leading: BackButton(onPressed: () => context.pop()),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Header card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                currencyFormat.format(group.totalCollected),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          StokvelTypeChip(type: group.type),
                        ],
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 16),
                          const Gap(4),
                          Text('${group.memberCount} members'),
                          const Gap(16),
                          Text(
                            '${currencyFormat.format(group.contributionAmount)}/month',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Contributions'),
                  Tab(text: 'Payouts'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(group: group),
                    _MembersTab(groupId: widget.groupId),
                    _ContributionsTab(groupId: widget.groupId),
                    _PayoutsTab(groupId: widget.groupId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Stokvel group;
  const _OverviewTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Group Stats',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(12),
              _StatRow(
                label: 'Total Collected',
                value: currencyFormat.format(group.totalCollected),
              ),
              _StatRow(
                label: 'Monthly Contribution',
                value: currencyFormat.format(group.contributionAmount),
              ),
              _StatRow(
                label: 'Frequency',
                value: group.contributionFrequency.toUpperCase(),
              ),
              _StatRow(
                label: 'Currency',
                value: group.currency,
              ),
            ],
          ),
        ),
        const Gap(8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WhatsApp Bot',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              Row(
                children: [
                  Icon(
                    group.whatsappGroupId != null
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    color: group.whatsappGroupId != null
                        ? AppColors.success
                        : AppColors.textSecondaryLight,
                    size: 20,
                  ),
                  const Gap(8),
                  Text(
                    group.whatsappGroupId != null
                        ? 'Connected'
                        : 'Not connected',
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Constitution',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              if (group.constitutionUrl != null)
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 20),
                    const Gap(8),
                    const Text('View Constitution'),
                    const Spacer(),
                    const Icon(Icons.open_in_new, size: 16),
                  ],
                )
              else
                Text(
                  'No constitution uploaded yet',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final String groupId;
  const _MembersTab({required this.groupId});

  IconData _roleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.chairperson:
        return Icons.star;
      case MemberRole.treasurer:
        return Icons.account_balance;
      case MemberRole.secretary:
        return Icons.edit_note;
      case MemberRole.member:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(stokvelMembersProvider(groupId));

    return membersAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (members) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...members.map((m) => AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(_roleIcon(m.role),
                            color: AppColors.primary, size: 20),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.displayName,
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            Text(
                              m.role.displayName +
                                  (m.rotationOrder != null
                                      ? ' #${m.rotationOrder}'
                                      : ''),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const Gap(16),
            AppButton(
              label: 'Invite Member',
              variant: AppButtonVariant.outline,
              onPressed: () async {
                final authState = ref.read(authStateProvider);
                if (authState.user == null) return;
                final code = await InviteService().createInvite(
                  stokvelId: groupId,
                  createdBy: authState.user!.uid,
                );
                final group =
                    ref.read(stokvelDetailProvider(groupId)).valueOrNull;
                if (context.mounted) {
                  context.pushNamed(
                    RouteNames.invite,
                    pathParameters: {'stokvelId': groupId},
                    queryParameters: {
                      'name': group?.name ?? '',
                      'code': code,
                    },
                  );
                }
              },
              icon: Icons.person_add_outlined,
            ),
          ],
        );
      },
    );
  }
}

/// Real Firestore-backed contributions tab.
class _ContributionsTab extends ConsumerWidget {
  final String groupId;
  const _ContributionsTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contribsAsync = ref.watch(groupedContributionsProvider(groupId));
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return contribsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (grouped) {
        // Sort month keys descending (most recent first)
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...sortedKeys.map((monthKey) {
              final contributions = grouped[monthKey]!;
              final parts = monthKey.split('-');
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final monthLabel =
                  DateFormat('MMMM yyyy').format(DateTime(year, month));

              // Count statuses
              final paidCount = contributions
                  .where((c) => c.status == ContributionStatus.paid)
                  .length;
              final totalAmount = contributions.fold<double>(
                  0, (sum, c) => c.status == ContributionStatus.paid ? sum + c.amount : sum);
              final allPaid =
                  paidCount == contributions.length && contributions.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monthLabel,
                      style: Theme.of(context).textTheme.titleLarge),
                  const Gap(8),
                  if (allPaid && contributions.isNotEmpty)
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const Gap(8),
                          Text('All ${contributions.length} paid'),
                          const Spacer(),
                          Text(
                              'Total: ${currencyFormat.format(totalAmount)}'),
                        ],
                      ),
                    )
                  else ...[
                    ...contributions.map((c) => _ContributionRow(
                          contribution: c,
                          groupId: groupId,
                        )),
                  ],
                  const Gap(4),
                  if (!allPaid)
                    Text(
                      '$paidCount/${contributions.length} paid \u00b7 ${currencyFormat.format(totalAmount)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const Gap(24),
                ],
              );
            }),

            // Record payment button
            AppButton(
              label: 'Record Payment',
              onPressed: () => context.pushNamed(
                RouteNames.recordContribution,
                pathParameters: {'groupId': groupId},
              ),
              icon: Icons.add,
            ),
          ],
        );
      },
    );
  }
}

class _ContributionRow extends StatelessWidget {
  final Contribution contribution;
  final String groupId;

  const _ContributionRow({
    required this.contribution,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    IconData icon;
    Color color;
    String status;

    switch (contribution.status) {
      case ContributionStatus.paid:
        icon = Icons.check_circle;
        color = AppColors.success;
        status = '';
      case ContributionStatus.late_:
        icon = Icons.cancel;
        color = AppColors.error;
        status = 'LATE';
      case ContributionStatus.excused:
        icon = Icons.info;
        color = AppColors.info;
        status = 'EXCUSED';
      case ContributionStatus.pending:
        icon = Icons.schedule;
        color = AppColors.warning;
        status = 'DUE';
    }

    return InkWell(
      onTap: () => context.pushNamed(
        RouteNames.contributionDetail,
        pathParameters: {
          'groupId': groupId,
          'contribId': contribution.id,
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(12),
            Expanded(child: Text(contribution.memberName)),
            Text(currencyFormat.format(contribution.amount)),
            if (status.isNotEmpty) ...[
              const Gap(8),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PayoutsTab extends ConsumerWidget {
  final String groupId;
  const _PayoutsTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutScheduleProvider(groupId));
    final groupAsync = ref.watch(stokvelDetailProvider(groupId));
    final authState = ref.watch(authStateProvider);
    final actionState = ref.watch(payoutActionProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);
    final dateFormat = DateFormat('MMM');
    final isBurial = groupAsync.valueOrNull?.type == StokvelType.burial;
    final currentUserId = authState.user?.uid;

    return payoutsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (payouts) {
        // Determine which payout is "current" (first scheduled)
        Payout? currentPayout;
        for (final p in payouts) {
          if (p.status == PayoutStatus.scheduled) {
            currentPayout = p;
            break;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              isBurial ? 'Claims' : 'Rotation Schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(12),
            if (payouts.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Gap(24),
                    Icon(Icons.event_note_outlined,
                        size: 48, color: AppColors.textSecondaryLight),
                    const Gap(8),
                    Text(
                      isBurial
                          ? 'No claims yet'
                          : 'No payout schedule generated',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const Gap(16),
                    if (!isBurial)
                      AppButton(
                        label: 'Generate Schedule',
                        variant: AppButtonVariant.outline,
                        isLoading: actionState.isLoading,
                        onPressed: () => ref
                            .read(payoutActionProvider.notifier)
                            .generateSchedule(groupId),
                        icon: Icons.auto_fix_high,
                      ),
                  ],
                ),
              )
            else
              ...payouts.map((payout) {
                final isPaid = payout.status == PayoutStatus.paid;
                final isCurrent = payout.id == currentPayout?.id;
                return InkWell(
                  onTap: () => context.pushNamed(
                    RouteNames.payoutDetail,
                    pathParameters: {
                      'groupId': groupId,
                      'payoutId': payout.id,
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            dateFormat.format(payout.payoutDate),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 32,
                          color: isPaid
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.divider,
                        ),
                        const Gap(12),
                        Icon(
                          isPaid
                              ? Icons.check_circle
                              : isCurrent
                                  ? Icons.play_circle_filled
                                  : Icons.radio_button_unchecked,
                          color: isPaid
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.textSecondaryLight,
                          size: 20,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            isCurrent
                                ? payout.recipientName.toUpperCase()
                                : payout.recipientName,
                            style: isCurrent
                                ? Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    )
                                : Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (isPaid)
                          Text(
                            currencyFormat.format(payout.amount),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const Gap(24),
            if (isBurial && currentUserId != null)
              AppButton(
                label: 'Request Payout',
                onPressed: () async {
                  final members =
                      ref.read(stokvelMembersProvider(groupId)).valueOrNull ??
                          [];
                  final me = members
                      .where((m) => m.userId == currentUserId)
                      .toList();
                  if (me.isEmpty) return;
                  await ref.read(payoutActionProvider.notifier).requestPayout(
                        stokvelId: groupId,
                        recipientId: currentUserId,
                        recipientName: me.first.displayName,
                        amount: 0,
                        type: PayoutType.burialClaim,
                        notes: 'Burial claim request',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout requested')),
                    );
                  }
                },
                icon: Icons.request_page,
              ),
          ],
        );
      },
    );
  }
}
