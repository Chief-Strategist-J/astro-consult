import 'package:equatable/equatable.dart';

import '../../app_constants.dart';
import 'auth_model.dart';

enum AuthStatus { initial, unauthenticated, otpPending, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.loading = false,
    this.error,
    this.role = UserRole.user,
    this.astrologerReady = false,
    this.isSignUp = false,
    this.name = '',
    this.phone = '',
    this.otp = '',
    this.showErrors = false,
    this.epoch = 0,
    this.user,
  });

  final AuthStatus status;
  final UserRole role; // portal chosen on the login screen
  final bool loading, isSignUp, showErrors, astrologerReady;
  final String? error;
  final String name, phone, otp;
  /// Bumped whenever the form fields must be rebuilt empty, so a field never shows text from an earlier attempt.
  final int epoch;
  final UserModel? user;

  String? get nameError =>
      showErrors && isSignUp && name.trim().length < AppConfig.nameMinLength ? AppStrings.errName : null;
  String? get phoneError =>
      showErrors && phone.length != AppConfig.phoneLength ? AppStrings.errPhone : null;
  String? get otpError => showErrors && otp.length != AppConfig.otpLength ? AppStrings.errOtp : null;

  AuthState copyWith({
    AuthStatus? status,
    bool? loading,
    String? error,
    bool clearError = false,
    UserRole? role,
    bool? astrologerReady,
    bool? isSignUp,
    String? name,
    String? phone,
    String? otp,
    bool? showErrors,
    int? epoch,
    UserModel? user,
  }) =>
      AuthState(
        status: status ?? this.status,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        role: role ?? this.role,
        astrologerReady: astrologerReady ?? this.astrologerReady,
        isSignUp: isSignUp ?? this.isSignUp,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        otp: otp ?? this.otp,
        showErrors: showErrors ?? this.showErrors,
        epoch: epoch ?? this.epoch,
        user: user ?? this.user,
      );

  @override
  List<Object?> get props => [status, loading, error, role, astrologerReady, isSignUp, name, phone, otp, showErrors, epoch, user];
}
