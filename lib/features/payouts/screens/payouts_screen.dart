import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/payout.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/payout_provider.dart';

class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(userPayoutsProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);
    final dateFormat = DateFormat('MMM yyyy');

    return payoutsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (payouts) {
        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up_outlined,
                    size: 64, color: AppColors.textSecondaryLight),
                const Gap(16),
                Text(
                  'No payouts yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          );
        }

        final upcoming = payouts
            .where((p) =>
                p.payout.status == PayoutStatus.scheduled ||
                p.payout.status == PayoutStatus.approved)
            .toList();
        final past = payouts
            .where((p) => p.payout.status == PayoutStatus.paid)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (upcoming.isNotEmpty) ...[
              Text('Upcoming Payouts',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              ...upcoming.map((entry) => AppCard(
                    onTap: () => context.pushNamed(
                      RouteNames.payoutDetail,
                      pathParameters: {
                        'groupId': entry.stokvelId,
                        'payoutId': entry.payout.id,
                      },
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up,
                                  color: AppColors.accent, size: 20),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.payout.status ==
                                            PayoutStatus.scheduled
                                        ? 'Scheduled'
                                        : 'Approved',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: AppColors.accent),
                                  ),
                                  Text(entry.stokvelName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(entry.payout.amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          dateFormat.format(entry.payout.payoutDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
            ],
            if (past.isNotEmpty) ...[
              const Gap(24),
              Text('Past Payouts',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(8),
              ...past.map((entry) => AppCard(
                    onTap: () => context.pushNamed(
                      RouteNames.payoutDetail,
                      pathParameters: {
                        'groupId': entry.stokvelId,
                        'payoutId': entry.payout.id,
                      },
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                        const Gap(8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.payout.recipientName} — ${dateFormat.format(entry.payout.payoutDate)}',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(entry.stokvelName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        ),
                        Text(currencyFormat.format(entry.payout.amount)),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}
