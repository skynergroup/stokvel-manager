import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../shared/models/user_profile.dart';

enum AuthStatus { initial, loading, codeSent, verified, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? verificationId;
  final int? resendToken;
  final String? phoneNumber;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.verificationId,
    this.resendToken,
    this.phoneNumber,
    this.error,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? verificationId,
    int? resendToken,
    String? phoneNumber,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  StreamSubscription<User?>? _authSub;

  void _init() {
    _authSub = _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.verified,
          user: user,
        );
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      phoneNumber: phoneNumber,
      error: null,
    );

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: state.resendToken,
      verificationCompleted: (credential) async {
        // Auto-verification on Android
        try {
          await _authService.signInWithCredential(credential);
        } catch (e) {
          state = state.copyWith(
            status: AuthStatus.error,
            error: e.toString(),
          );
        }
      },
      verificationFailed: (e) {
        state = state.copyWith(
          status: AuthStatus.error,
          error: e.message ?? 'Verification failed',
        );
      },
      codeSent: (verificationId, resendToken) {
        state = state.copyWith(
          status: AuthStatus.codeSent,
          verificationId: verificationId,
          resendToken: resendToken,
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        state = state.copyWith(verificationId: verificationId);
      },
    );
  }

  Future<void> verifyOtp(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'No verification ID. Please request a new code.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final credential = _authService.createCredential(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );
      await _authService.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.codeSent,
        error: _mapAuthError(e.code),
      );
    }
  }

  Future<void> resendCode() async {
    if (state.phoneNumber == null) return;
    await verifyPhoneNumber(state.phoneNumber!);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.code == 'sign-in-cancelled'
            ? null
            : _mapAuthError(e.code),
      );
      if (e.code == 'sign-in-cancelled') {
        state = state.copyWith(status: AuthStatus.initial);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Invalid code. Please try again.';
      case 'session-expired':
        return 'Code expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

final firebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.user == null) return Stream.value(null);
  return UserService().streamProfile(authState.user!.uid);
});

final hasProfileProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.user == null) return false;
  final profile = await UserService().getProfile(authState.user!.uid);
  return profile != null && profile.displayName.isNotEmpty;
});
