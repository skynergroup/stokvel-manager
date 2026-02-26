import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/member.dart';
import '../../../shared/models/stokvel.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/group_service.dart';
import '../services/invite_service.dart';

final groupServiceProvider = Provider<GroupService>((ref) => GroupService());
final inviteServiceProvider = Provider<InviteService>((ref) => InviteService());

final userStokvelsProvider = StreamProvider<List<Stokvel>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return Stream.value([]);
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getUserStokvels(profile.stokvels);
});

final stokvelDetailProvider =
    StreamProvider.family<Stokvel?, String>((ref, stokvelId) {
  return ref.watch(groupServiceProvider).streamStokvel(stokvelId);
});

final stokvelMembersProvider =
    StreamProvider.family<List<StokvelMember>, String>((ref, stokvelId) {
  return ref.watch(groupServiceProvider).streamMembers(stokvelId);
});

class CreateStokvelNotifier extends StateNotifier<AsyncValue<String?>> {
  final GroupService _groupService;

  CreateStokvelNotifier(this._groupService)
      : super(const AsyncValue.data(null));

  Future<String?> create({
    required String name,
    required String type,
    required double contributionAmount,
    required String contributionFrequency,
    required String createdBy,
    required String creatorName,
    required String creatorPhone,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final stokvelId = await _groupService.createStokvel(
        name: name,
        type: type,
        contributionAmount: contributionAmount,
        contributionFrequency: contributionFrequency,
        createdBy: createdBy,
        description: description,
      );

      // Add creator as chairperson
      await _groupService.addMember(
        stokvelId: stokvelId,
        userId: createdBy,
        displayName: creatorName,
        phone: creatorPhone,
        role: MemberRole.chairperson,
        rotationOrder: 1,
      );

      state = AsyncValue.data(stokvelId);
      return stokvelId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final createStokvelProvider =
    StateNotifierProvider<CreateStokvelNotifier, AsyncValue<String?>>((ref) {
  return CreateStokvelNotifier(
    ref.watch(groupServiceProvider),
  );
});

final inviteCodeProvider =
    FutureProvider.family<String, ({String stokvelId, String userId})>(
        (ref, params) async {
  final inviteService = ref.watch(inviteServiceProvider);
  return inviteService.createInvite(
    stokvelId: params.stokvelId,
    createdBy: params.userId,
  );
});
