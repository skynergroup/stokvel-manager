import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/stokvel_type_chip.dart';
import '../providers/groups_provider.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsListProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.pushNamed(RouteNames.notifications),
          ),
        ],
      ),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.groups_outlined,
              title: 'No stokvels yet',
              message:
                  "You're not in any stokvels yet. Create one or ask your chairperson for an invite link.",
              actionLabel: 'Create Stokvel',
              onAction: () => context.pushNamed(RouteNames.createGroup),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return AppCard(
                  onTap: () => context.pushNamed(
                    RouteNames.groupDetail,
                    pathParameters: {'id': group.id},
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StokvelTypeChip(type: group.type),
                        ],
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 16),
                          const Gap(4),
                          Text(
                            '${group.memberCount} members',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Gap(16),
                          Text(
                            '${currencyFormat.format(group.contributionAmount)}/month',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        'Balance: ${currencyFormat.format(group.totalCollected)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createGroup),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}
