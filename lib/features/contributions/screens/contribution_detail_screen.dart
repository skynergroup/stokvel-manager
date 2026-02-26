import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/contribution.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/contribution_provider.dart';

class ContributionDetailScreen extends ConsumerWidget {
  final String groupId;
  final String contribId;

  const ContributionDetailScreen({
    super.key,
    required this.groupId,
    required this.contribId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contribAsync = ref.watch(contributionDetailProvider(
        (stokvelId: groupId, contribId: contribId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution Detail'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: contribAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (contribution) {
          if (contribution == null) {
            return const Center(child: Text('Contribution not found'));
          }
          return _DetailContent(
            contribution: contribution,
            groupId: groupId,
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Contribution contribution;
  final String groupId;

  const _DetailContent({
    required this.contribution,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge and amount
          Center(
            child: Column(
              children: [
                _StatusBadge(status: contribution.status),
                const Gap(16),
                Text(
                  currencyFormat.format(contribution.amount),
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap(4),
                Text(
                  contribution.memberName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          const Gap(32),

          // Details card
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Member',
                  value: contribution.memberName,
                  icon: Icons.person_outline,
                ),
                const Divider(),
                _DetailRow(
                  label: 'Amount',
                  value: currencyFormat.format(contribution.amount),
                  icon: Icons.payments_outlined,
                ),
                const Divider(),
                _DetailRow(
                  label: 'Due Date',
                  value: dateFormat.format(contribution.dueDate),
                  icon: Icons.event_outlined,
                ),
                if (contribution.paidDate != null) ...[
                  const Divider(),
                  _DetailRow(
                    label: 'Date Paid',
                    value: dateFormat.format(contribution.paidDate!),
                    icon: Icons.check_circle_outline,
                  ),
                ],
                const Divider(),
                _DetailRow(
                  label: 'Status',
                  value: contribution.status.displayName,
                  icon: Icons.info_outline,
                ),
                if (contribution.notes != null &&
                    contribution.notes!.isNotEmpty) ...[
                  const Divider(),
                  _DetailRow(
                    label: 'Notes',
                    value: contribution.notes!,
                    icon: Icons.note_outlined,
                  ),
                ],
              ],
            ),
          ),

          // Proof of payment
          if (contribution.proofUrl != null) ...[
            const Gap(24),
            Text('Proof of Payment',
                style: Theme.of(context).textTheme.titleLarge),
            const Gap(8),
            GestureDetector(
              onTap: () => _showFullScreenProof(context, contribution.proofUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: contribution.proofUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: LoadingIndicator()),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: AppColors.divider,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, size: 48),
                          Gap(8),
                          Text('Could not load image'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(4),
            Text(
              'Tap to view full screen',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenProof(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenProof(url: url),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ContributionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case ContributionStatus.paid:
        color = AppColors.success;
        icon = Icons.check_circle;
      case ContributionStatus.pending:
        color = AppColors.warning;
        icon = Icons.schedule;
      case ContributionStatus.late_:
        color = AppColors.error;
        icon = Icons.cancel;
      case ContributionStatus.excused:
        color = AppColors.info;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryLight),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Gap(2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenProof extends StatelessWidget {
  final String url;

  const _FullScreenProof({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Proof of Payment'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
