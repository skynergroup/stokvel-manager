import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Phone Auth ──────────────────────────────────────────────

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    return _auth.signInWithCredential(credential);
  }

  PhoneAuthCredential createCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  // ── Google Sign-In (v7 API) ─────────────────────────────────

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  /// Google Sign-In: triggers authenticate → listens for sign-in event → Firebase credential
  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleSignIn = GoogleSignIn.instance;
    final completer = Completer<UserCredential>();

    late StreamSubscription<GoogleSignInAuthenticationEvent> sub;
    sub = googleSignIn.authenticationEvents.listen((event) async {
      try {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn(:final user):
            // v7: idToken comes from user.authentication
            final idToken = user.authentication.idToken;

            final credential = GoogleAuthProvider.credential(
              idToken: idToken,
            );

            final userCredential =
                await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(userCredential);
            }
          case GoogleSignInAuthenticationEventSignOut():
            if (!completer.isCompleted) {
              completer.completeError(
                FirebaseAuthException(
                  code: 'sign-in-cancelled',
                  message: 'Google sign-in was cancelled',
                ),
              );
            }
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      } finally {
        sub.cancel();
      }
    }, onError: (Object e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      sub.cancel();
    });

    // Trigger the authentication UI
    try {
      await googleSignIn.authenticate();
    } catch (e) {
      sub.cancel();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        sub.cancel();
        throw FirebaseAuthException(
          code: 'sign-in-timeout',
          message: 'Google sign-in timed out',
        );
      },
    );
  }

  // ── Sign Out ────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.disconnect();
      }
    } catch (_) {}
    await _auth.signOut();
  }
}
