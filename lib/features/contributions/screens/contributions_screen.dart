import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),

        // Upcoming contributions
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Umoja Savings',
                  style: Theme.of(context).textTheme.titleSmall),
              const Gap(4),
              Row(
                children: [
                  Text(
                    '${currencyFormat.format(500)} due 28 Feb',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kasi Burial Society',
                  style: Theme.of(context).textTheme.titleSmall),
              const Gap(4),
              Row(
                children: [
                  Text(
                    '${currencyFormat.format(200)} due 28 Feb',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Paid',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Gap(24),
        Text('History', style: Theme.of(context).textTheme.titleLarge),
        const Gap(8),
        _HistoryRow(month: 'Jan', amount: 700, groups: 2),
        _HistoryRow(month: 'Dec', amount: 700, groups: 2),
        _HistoryRow(month: 'Nov', amount: 700, groups: 2),
      ],
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
            '${currencyFormat.format(amount)} ($groups groups)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
