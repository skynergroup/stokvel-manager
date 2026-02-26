import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Upcoming Payouts', style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
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
                        Text('Your turn!',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppColors.accent)),
                        Text('Umoja Savings',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(6000),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
              const Gap(8),
              Text(
                'March 2026',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const Gap(24),
        Text('Rotation Schedule — Umoja Savings',
            style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        ...[
          ('Jan', 'Nomsa M.', true, false),
          ('Feb', 'Sipho S.', true, false),
          ('Mar', 'THABO M.', false, true),
          ('Apr', 'Lerato K.', false, false),
          ('May', 'Bongani D.', false, false),
        ].map((entry) {
          final (month, name, isPaid, isCurrent) = entry;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(month,
                      style: Theme.of(context).textTheme.labelMedium),
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
                    name,
                    style: isCurrent
                        ? Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            )
                        : Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (isPaid)
                  Text(
                    currencyFormat.format(6000),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          );
        }),

        const Gap(24),
        Text('Past Payouts', style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomsa M. — Jan 2026',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('Umoja Savings',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(currencyFormat.format(6000)),
            ],
          ),
        ),
      ],
    );
  }
}
