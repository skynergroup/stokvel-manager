import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/stokvel_type_chip.dart';
import '../providers/groups_provider.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stokvelsAsync = ref.watch(userStokvelsProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myGroups),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.pushNamed(RouteNames.notifications),
          ),
        ],
      ),
      body: stokvelsAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const Gap(8),
              Text('${l10n.failedToLoadGroups}\n$error',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: l10n.noStokvelsYet,
              message: l10n.noStokvelsMessage,
              actionLabel: l10n.createStokvel,
              onAction: () => context.pushNamed(RouteNames.createGroup),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userStokvelsProvider),
            child: ListView.builder(
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
                            l10n.membersCount(group.memberCount),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Gap(16),
                          Text(
                            l10n.perMonth(currencyFormat.format(group.contributionAmount)),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        l10n.balanceAmount(currencyFormat.format(group.totalCollected)),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createGroup),
        icon: const Icon(Icons.add),
        label: Text(l10n.create),
      ),
    );
  }
}
