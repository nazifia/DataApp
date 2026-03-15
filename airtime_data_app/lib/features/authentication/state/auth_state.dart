// Authentication States
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String userId;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String? profilePicture;

  const AuthSuccess({
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    this.email,
    this.profilePicture,
  });

  @override
  List<Object> get props =>
      [userId, phoneNumber, fullName, email ?? '', profilePicture ?? ''];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class LoginSuccess extends AuthState {
  const LoginSuccess();
}

// OTP Specific States
class OtpLoading extends AuthState {
  const OtpLoading();
}

class OtpSuccess extends AuthState {
  final String verificationId;

  const OtpSuccess(this.verificationId);

  @override
  List<Object> get props => [verificationId];
}

class OtpFailure extends AuthState {
  final String message;

  const OtpFailure(this.message);

  @override
  List<Object> get props => [message];
}

class OtpVerified extends AuthState {
  final bool isNewUser;

  const OtpVerified({this.isNewUser = true});

  @override
  List<Object> get props => [isNewUser];
}

class OtpVerificationFailed extends AuthState {
  final String message;

  const OtpVerificationFailed(this.message);

  @override
  List<Object> get props => [message];
}

// Profile States
class ProfileLoading extends AuthState {
  const ProfileLoading();
}

class ProfileSuccess extends AuthState {
  final Map<String, dynamic> profileData;

  const ProfileSuccess(this.profileData);

  @override
  List<Object> get props => [profileData];
}

class ProfileFailure extends AuthState {
  final String message;

  const ProfileFailure(this.message);

  @override
  List<Object> get props => [message];
}

// Wallet States
class WalletLoading extends AuthState {
  const WalletLoading();
}

class WalletSuccess extends AuthState {
  final double balance;

  const WalletSuccess(this.balance);

  @override
  List<Object> get props => [balance];
}

class WalletFailure extends AuthState {
  final String message;

  const WalletFailure(this.message);

  @override
  List<Object> get props => [message];
}

// Password Change States
class PasswordChangedSuccess extends AuthState {
  const PasswordChangedSuccess();
}

class PasswordChangedFailure extends AuthState {
  final String message;

  const PasswordChangedFailure(this.message);

  @override
  List<Object> get props => [message];
}
