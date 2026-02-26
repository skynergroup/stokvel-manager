import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/user_service.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.user == null) return Stream.value(null);
  return ref.watch(userServiceProvider).streamProfile(authState.user!.uid);
});

final darkModeProvider = StateProvider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return profile?.settings.darkMode ?? false;
});
