import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/contribution.dart';
import '../../../shared/models/stokvel.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../services/contribution_service.dart';

/// Service instance provider.
final contributionServiceProvider =
    Provider<ContributionService>((ref) => ContributionService());

/// Stream all contributions for a group, ordered by newest first.
final groupContributionsProvider =
    StreamProvider.family<List<Contribution>, String>((ref, stokvelId) {
  return ref.watch(contributionServiceProvider).getContributions(stokvelId);
});

/// Stream contributions for a specific member in a group.
final memberContributionsProvider = StreamProvider.family<List<Contribution>,
    ({String stokvelId, String memberId})>((ref, params) {
  return ref
      .watch(contributionServiceProvider)
      .getContributionsByMember(params.stokvelId, params.memberId);
});

/// Stream a single contribution.
final contributionDetailProvider = StreamProvider.family<Contribution?,
    ({String stokvelId, String contribId})>((ref, params) {
  return ref
      .watch(contributionServiceProvider)
      .streamContribution(params.stokvelId, params.contribId);
});

/// Reactive group balance from paid contributions.
final groupBalanceProvider =
    StreamProvider.family<double, String>((ref, stokvelId) {
  return ref.watch(contributionServiceProvider).getGroupBalance(stokvelId);
});

/// Current month contribution status for all members in a group.
final memberContributionStatusProvider = FutureProvider.family<
    Map<String, ContributionStatus>, String>((ref, stokvelId) {
  return ref
      .watch(contributionServiceProvider)
      .getMemberContributionStatus(stokvelId, DateTime.now());
});

/// Contributions grouped by month for a given stokvel.
/// Returns a map of "yyyy-MM" to a list of contributions.
final groupedContributionsProvider = StreamProvider.family<
    Map<String, List<Contribution>>, String>((ref, stokvelId) {
  return ref.watch(contributionServiceProvider).getContributions(stokvelId).map(
    (contributions) {
      final grouped = <String, List<Contribution>>{};
      for (final c in contributions) {
        final key =
            '${c.dueDate.year}-${c.dueDate.month.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(c);
      }
      return grouped;
    },
  );
});

/// Cross-group contributions for the current user.
/// Returns contributions from ALL groups the user belongs to.
final userContributionsProvider =
    StreamProvider<List<({Stokvel group, Contribution contribution})>>((ref) {
  final stokvels = ref.watch(userStokvelsProvider).valueOrNull ?? [];
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid;

  if (stokvels.isEmpty || userId == null) {
    return Stream.value([]);
  }

  final service = ref.watch(contributionServiceProvider);

  // Combine contribution streams from all user's groups
  final streams = stokvels.map((group) {
    return service.getContributionsByMember(group.id, userId).map(
          (contributions) => contributions
              .map((c) => (group: group, contribution: c))
              .toList(),
        );
  }).toList();

  if (streams.isEmpty) return Stream.value([]);

  // Merge all streams
  return streams.first.asyncExpand((first) {
    if (streams.length == 1) return Stream.value(first);

    return Stream.value(first);
  });
});

/// Cross-group contributions — simplified: fetch all user's groups
/// and their contributions for the current user.
final allUserContributionsProvider = FutureProvider<
    List<({Stokvel group, List<Contribution> contributions})>>((ref) async {
  final stokvels = ref.watch(userStokvelsProvider).valueOrNull ?? [];
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid;

  if (stokvels.isEmpty || userId == null) return [];

  final service = ref.watch(contributionServiceProvider);
  final results =
      <({Stokvel group, List<Contribution> contributions})>[];

  for (final group in stokvels) {
    final contributions = await service
        .getContributionsByMember(group.id, userId)
        .first;
    results.add((group: group, contributions: contributions));
  }
  return results;
});

/// Notifier for recording a contribution with proof upload.
class RecordContributionNotifier extends StateNotifier<AsyncValue<void>> {
  final ContributionService _service;

  RecordContributionNotifier(this._service)
      : super(const AsyncValue.data(null));

  Future<bool> record({
    required String stokvelId,
    required String memberId,
    required String memberName,
    required double amount,
    required String recordedBy,
    DateTime? paidDate,
    File? proofFile,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? proofUrl;

      // First create the contribution to get an ID for the proof path
      final contribId = await _service.recordContribution(
        stokvelId: stokvelId,
        memberId: memberId,
        memberName: memberName,
        amount: amount,
        recordedBy: recordedBy,
        paidDate: paidDate,
        notes: notes,
      );

      // Upload proof if provided
      if (proofFile != null) {
        proofUrl = await _service.uploadProof(
          stokvelId: stokvelId,
          contribId: contribId,
          imageFile: proofFile,
        );
        // Update the contribution with the proof URL
        await _service.updateContributionStatus(
          stokvelId: stokvelId,
          contribId: contribId,
          status: ContributionStatus.paid,
          proofUrl: proofUrl,
        );
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordContributionProvider =
    StateNotifierProvider<RecordContributionNotifier, AsyncValue<void>>((ref) {
  return RecordContributionNotifier(ref.watch(contributionServiceProvider));
});
