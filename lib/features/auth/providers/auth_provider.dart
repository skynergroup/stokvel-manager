import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? displayName;
  final String? phone;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.displayName,
    this.phone,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? displayName,
    String? phone,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void login({
    required String userId,
    required String displayName,
    required String phone,
  }) {
    state = AuthState(
      isLoggedIn: true,
      userId: userId,
      displayName: displayName,
      phone: phone,
    );
  }

  void logout() {
    state = const AuthState();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
