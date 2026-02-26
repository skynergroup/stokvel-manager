import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/payout.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../providers/payout_provider.dart';

class PayoutDetailScreen extends ConsumerWidget {
  final String groupId;
  final String payoutId;

  const PayoutDetailScreen({
    super.key,
    required this.groupId,
    required this.payoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutAsync = ref.watch(
      payoutDetailProvider((stokvelId: groupId, payoutId: payoutId)),
    );
    final membersAsync = ref.watch(stokvelMembersProvider(groupId));
    final groupAsync = ref.watch(stokvelDetailProvider(groupId));
    final authState = ref.watch(authStateProvider);
    final actionState = ref.watch(payoutActionProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Detail'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: payoutAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (payout) {
          if (payout == null) {
            return const Center(child: Text('Payout not found'));
          }

          final groupName =
              groupAsync.valueOrNull?.name ?? 'Loading...';
          final members = membersAsync.valueOrNull ?? [];
          final currentUserId = authState.user?.uid;

          // Check if current user is chairperson
          final isChair = members.any((m) =>
              m.userId == currentUserId &&
              m.role.name == 'chairperson');

          final hasApproved =
              payout.approvedBy.contains(currentUserId);

          Color statusColor;
          IconData statusIcon;
          switch (payout.status) {
            case PayoutStatus.scheduled:
              statusColor = AppColors.warning;
              statusIcon = Icons.schedule;
            case PayoutStatus.approved:
              statusColor = AppColors.info;
              statusIcon = Icons.thumb_up;
            case PayoutStatus.paid:
              statusColor = AppColors.success;
              statusIcon = Icons.check_circle;
            case PayoutStatus.disputed:
              statusColor = AppColors.error;
              statusIcon = Icons.warning;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status header
              AppCard(
                color: statusColor.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 32),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payout.status.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: statusColor),
                          ),
                          Text(groupName,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(payout.amount),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Details
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Details',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Gap(12),
                    _DetailRow(
                        label: 'Recipient', value: payout.recipientName),
                    _DetailRow(
                        label: 'Amount',
                        value: currencyFormat.format(payout.amount)),
                    _DetailRow(
                        label: 'Date',
                        value: dateFormat.format(payout.payoutDate)),
                    _DetailRow(
                        label: 'Type', value: payout.type.displayName),
                    _DetailRow(
                        label: 'Status',
                        value: payout.status.displayName),
                    if (payout.notes != null && payout.notes!.isNotEmpty)
                      _DetailRow(label: 'Notes', value: payout.notes!),
                  ],
                ),
              ),
              const Gap(16),

              // Approvals
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Approvals (${payout.approvedBy.length})',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Gap(8),
                    if (payout.approvedBy.isEmpty)
                      Text('No approvals yet',
                          style: Theme.of(context).textTheme.bodySmall)
                    else
                      ...payout.approvedBy.map((approverId) {
                        final member = members
                            .where((m) => m.userId == approverId)
                            .toList();
                        final name = member.isNotEmpty
                            ? member.first.displayName
                            : approverId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 18),
                              const Gap(8),
                              Text(name),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const Gap(24),

              // Actions
              if (isChair &&
                  payout.status == PayoutStatus.scheduled &&
                  !hasApproved)
                AppButton(
                  label: 'Approve Payout',
                  isLoading: actionState.isLoading,
                  icon: Icons.thumb_up_outlined,
                  onPressed: () async {
                    final success =
                        await ref.read(payoutActionProvider.notifier).approvePayout(
                              stokvelId: groupId,
                              payoutId: payoutId,
                              approverId: currentUserId!,
                            );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payout approved')),
                      );
                    }
                  },
                ),
              if (isChair &&
                  (payout.status == PayoutStatus.approved ||
                      payout.status == PayoutStatus.scheduled)) ...[
                const Gap(12),
                AppButton(
                  label: 'Mark as Paid',
                  variant: AppButtonVariant.secondary,
                  isLoading: actionState.isLoading,
                  icon: Icons.payment,
                  onPressed: () async {
                    final success =
                        await ref.read(payoutActionProvider.notifier).markPaid(
                              stokvelId: groupId,
                              payoutId: payoutId,
                            );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payout marked as paid')),
                      );
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Gap(16),
          Flexible(
            child: Text(value,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
