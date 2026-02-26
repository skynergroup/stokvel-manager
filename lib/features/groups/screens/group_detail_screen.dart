import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/member.dart';
import '../../../shared/models/stokvel.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/stokvel_type_chip.dart';
import '../../auth/providers/auth_provider.dart';
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

class _ContributionsTab extends StatelessWidget {
  final String groupId;
  const _ContributionsTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('February 2026',
            style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        _ContributionRow(name: 'Nomsa M.', amount: 500, isPaid: true),
        _ContributionRow(name: 'Sipho S.', amount: 500, isPaid: true),
        _ContributionRow(name: 'Thabo M.', amount: 500, isPaid: true),
        _ContributionRow(name: 'Lerato K.', amount: 500, isPending: true),
        _ContributionRow(name: 'Bongani D.', amount: 500, isLate: true),
        const Gap(8),
        Text(
          '3/5 paid \u00b7 R1,500',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Gap(24),
        Text('January 2026',
            style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
              const Gap(8),
              const Text('All 5 paid'),
              const Spacer(),
              const Text('Total: R2,500'),
            ],
          ),
        ),
        const Gap(24),
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
  }
}

class _ContributionRow extends StatelessWidget {
  final String name;
  final double amount;
  final bool isPaid;
  final bool isPending;
  final bool isLate;

  const _ContributionRow({
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.isPending = false,
    this.isLate = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    IconData icon;
    Color color;
    String status;

    if (isPaid) {
      icon = Icons.check_circle;
      color = AppColors.success;
      status = '';
    } else if (isLate) {
      icon = Icons.cancel;
      color = AppColors.error;
      status = 'LATE';
    } else {
      icon = Icons.schedule;
      color = AppColors.warning;
      status = 'DUE';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Expanded(child: Text(name)),
          Text(currencyFormat.format(amount)),
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
    );
  }
}

class _PayoutsTab extends StatelessWidget {
  final String groupId;
  const _PayoutsTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    final payouts = [
      ('Jan', 'Nomsa M.', true, false),
      ('Feb', 'Sipho S.', true, false),
      ('Mar', 'Thabo M.', false, true),
      ('Apr', 'Lerato K.', false, false),
      ('May', 'Bongani D.', false, false),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Rotation Schedule',
            style: Theme.of(context).textTheme.titleLarge),
        const Gap(12),
        ...payouts.map((p) {
          final isPaid = p.$3;
          final isCurrent = p.$4;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    p.$1,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Icon(
                  isPaid
                      ? Icons.check_circle
                      : isCurrent
                          ? Icons.play_arrow
                          : Icons.radio_button_unchecked,
                  color: isPaid
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    isCurrent ? p.$2.toUpperCase() : p.$2,
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
                if (isPaid) Text(currencyFormat.format(2500)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
