import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import 'auth_model.dart';
import 'auth_state.dart';

class Backend {
  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
  static String? get uid => auth.currentUser?.uid;

  static Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    final r = await functions.httpsCallable(name).call<Map<Object?, Object?>>(data);
    return Map<String, dynamic>.from(r.data);
  }

  static String message(Object e) {
    if (e is FirebaseFunctionsException) {
      if (e.code == ErrorCodes.unauthenticated) return AppStrings.errorSignedOut;
      if (e.code == ErrorCodes.unavailable || e.code == ErrorCodes.deadlineExceeded) return AppStrings.errorNetwork;
      return (e.message?.isNotEmpty ?? false) ? e.message! : AppStrings.errorGeneric;
    }
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        ErrorCodes.invalidPhoneNumber => AppStrings.errInvalidPhone,
        ErrorCodes.invalidVerificationCode => AppStrings.errInvalidCode,
        ErrorCodes.sessionExpired || ErrorCodes.codeExpired => AppStrings.errCodeExpired,
        ErrorCodes.tooManyRequests || ErrorCodes.quotaExceeded => AppStrings.errTooManyRequests,
        ErrorCodes.networkRequestFailed => AppStrings.errorNetwork,
        _ => AppStrings.errorGeneric,
      };
    }
    if (e is FirebaseException) {
      if (e.code == ErrorCodes.permissionDenied) return AppStrings.errorPermission;
      if (e.code == ErrorCodes.unavailable) return AppStrings.errorNetwork;
    }
    return AppStrings.errorGeneric;
  }
}

/// The signed-in user's id as seen by the UI (read from [AuthCubit], not from Firebase).
extension AuthContext on BuildContext {
  String? get myUid => read<AuthCubit>().state.user?.id;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  void setName(String v) => emit(state.copyWith(name: v));
  void setPhone(String v) => emit(state.copyWith(phone: v));
  void setOtp(String v) => emit(state.copyWith(otp: v));
  void setRole(UserRole r) {
    if (state.loading) return;
    emit(state.copyWith(role: r, showErrors: false, clearError: true));
  }

  void markAstrologerReady() => emit(state.copyWith(astrologerReady: true));

  void toggleMode() {
    if (state.loading) return;
    emit(state.copyWith(isSignUp: !state.isSignUp, showErrors: false, clearError: true));
  }

  /// Resumes the saved login. Firebase restores the session asynchronously (always on web), so wait for its first
  /// auth event instead of reading `currentUser` immediately, and retry transient failures before showing the login
  /// form: a hiccup must never make people re-enter their details.
  Future<void> restore() async {
    final user = await Backend.auth.authStateChanges().first;
    if (user == null) return emit(state.copyWith(status: AuthStatus.unauthenticated));
    for (var attempt = 1; attempt <= AppConfig.restoreAttempts; attempt++) {
      try {
        final profile = await _loadProfile(user);
        return emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: profile,
          role: profile.role,
          astrologerReady: await _hasAstrologerProfile(profile),
        ));
      } catch (_) {
        if (isClosed) return;
        if (attempt < AppConfig.restoreAttempts) await Future<void>.delayed(AppConfig.restoreRetryDelay * attempt);
      }
    }
    // Still signed in with Firebase, just unable to load right now: keep the session, tell the user.
    emit(state.copyWith(status: AuthStatus.unauthenticated, error: AppStrings.errorNetwork));
  }

  Future<void> sendOtp({bool resend = false}) async {
    if (state.loading) return;
    emit(state.copyWith(showErrors: true));
    if (state.phoneError != null || state.nameError != null) return;
    emit(state.copyWith(loading: true, clearError: true));
    final fullPhone = AppConfig.fullPhone(state.phone);
    if (kIsWeb) {
      try {
        _webConfirmation = await Backend.auth.signInWithPhoneNumber(fullPhone);
        if (!isClosed) {
          emit(state.copyWith(loading: false, status: AuthStatus.otpPending, otp: '', showErrors: false));
        }
      } catch (e) {
        if (!isClosed) emit(state.copyWith(loading: false, error: Backend.message(e)));
      }
      return;
    }
    await Backend.auth.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: AppConfig.otpTimeout,
      forceResendingToken: resend ? _resendToken : null,
      verificationCompleted: (cred) => _signIn(cred),
      verificationFailed: (e) {
        if (!isClosed) emit(state.copyWith(loading: false, error: Backend.message(e)));
      },
      codeSent: (id, token) {
        _verificationId = id;
        _resendToken = token;
        if (!isClosed) {
          emit(state.copyWith(loading: false, status: AuthStatus.otpPending, otp: '', showErrors: false));
        }
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  Future<void> verifyOtp() async {
    if (state.loading) return;
    emit(state.copyWith(showErrors: true));
    if (state.otpError != null) return;
    if (kIsWeb) {
      if (_webConfirmation == null) return;
      if (isClosed) return;
      emit(state.copyWith(loading: true, clearError: true));
      try {
        final result = await _webConfirmation!.confirm(state.otp);
        await _finishSignIn(result.user!);
      } catch (e) {
        emit(state.copyWith(loading: false, error: Backend.message(e)));
      }
      return;
    }
    if (_verificationId == null) return;
    await _signIn(PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: state.otp));
  }

  Future<void> _signIn(AuthCredential cred) async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final result = await Backend.auth.signInWithCredential(cred);
      await _finishSignIn(result.user!);
    } catch (e) {
      emit(state.copyWith(loading: false, error: Backend.message(e)));
    }
  }

  /// Loads the profile and enforces the portal: a user number cannot enter the astrologer area or vice versa.
  Future<void> _finishSignIn(User user) async {
    final profile = await _loadProfile(user);
    if (profile.role != state.role) {
      await Backend.auth.signOut();
      return emit(state.copyWith(
        loading: false,
        status: AuthStatus.unauthenticated,
        error: AppStrings.errWrongRole(profile.role.label),
      ));
    }
    emit(state.copyWith(
      loading: false,
      status: AuthStatus.authenticated,
      user: profile,
      astrologerReady: await _hasAstrologerProfile(profile),
    ));
  }

  Future<bool> _hasAstrologerProfile(UserModel u) async {
    if (u.role != UserRole.astrologer) return false;
    return (await Backend.db.collection(Db.astrologers).doc(u.id).get()).exists;
  }

  Future<UserModel> _loadProfile(User user) async {
    final ref = Backend.db.collection(Db.users).doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        Db.name: state.name.trim(),
        Db.phone: user.phoneNumber ?? AppConfig.fullPhone(state.phone),
        Db.role: state.role.name,
        Db.dob: null,
        Db.birthTime: null,
        Db.birthPlace: null,
        Db.createdAt: FieldValue.serverTimestamp(),
      });
      return UserModel.fromDoc(await ref.get());
    }
    return UserModel.fromDoc(snap);
  }

  void backToLogin() {
    if (state.loading) return;
    emit(state.copyWith(status: AuthStatus.unauthenticated, otp: '', showErrors: false, clearError: true));
  }

  void updateUser(UserModel user) => emit(state.copyWith(user: user));

  Future<void> logout() async {
    await Backend.auth.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
