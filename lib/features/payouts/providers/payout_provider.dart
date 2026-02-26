import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/payout.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../services/payout_service.dart';

/// Service instance provider.
final payoutServiceProvider =
    Provider<PayoutService>((ref) => PayoutService());

/// Stream payout schedule for a group, ordered by date.
final payoutScheduleProvider =
    StreamProvider.family<List<Payout>, String>((ref, stokvelId) {
  return ref.watch(payoutServiceProvider).getPayoutSchedule(stokvelId);
});

/// Next scheduled payout for a group.
final nextPayoutProvider =
    StreamProvider.family<Payout?, String>((ref, stokvelId) {
  return ref.watch(payoutServiceProvider).getNextPayout(stokvelId);
});

/// Stream a single payout.
final payoutDetailProvider = StreamProvider.family<Payout?,
    ({String stokvelId, String payoutId})>((ref, params) {
  return ref
      .watch(payoutServiceProvider)
      .streamPayout(params.stokvelId, params.payoutId);
});

/// All payouts for the current user across all groups.
final userPayoutsProvider = FutureProvider<
    List<({String stokvelId, String stokvelName, Payout payout})>>((ref) async {
  final stokvels = ref.watch(userStokvelsProvider).valueOrNull ?? [];
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid;

  if (stokvels.isEmpty || userId == null) return [];

  final stokvelIds = stokvels.map((s) => s.id).toList();
  return ref
      .watch(payoutServiceProvider)
      .getUserUpcomingPayouts(userId, stokvelIds);
});

/// Notifier for payout actions: request, approve, mark paid.
class PayoutActionNotifier extends StateNotifier<AsyncValue<void>> {
  final PayoutService _service;

  PayoutActionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> requestPayout({
    required String stokvelId,
    required String recipientId,
    required String recipientName,
    required double amount,
    required PayoutType type,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.requestPayout(
        stokvelId: stokvelId,
        recipientId: recipientId,
        recipientName: recipientName,
        amount: amount,
        type: type,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> approvePayout({
    required String stokvelId,
    required String payoutId,
    required String approverId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.approvePayout(
        stokvelId: stokvelId,
        payoutId: payoutId,
        approverId: approverId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> markPaid({
    required String stokvelId,
    required String payoutId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.markPayoutPaid(
        stokvelId: stokvelId,
        payoutId: payoutId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> generateSchedule(String stokvelId) async {
    state = const AsyncValue.loading();
    try {
      await _service.createRotationSchedule(stokvelId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final payoutActionProvider =
    StateNotifierProvider<PayoutActionNotifier, AsyncValue<void>>((ref) {
  return PayoutActionNotifier(ref.watch(payoutServiceProvider));
});
