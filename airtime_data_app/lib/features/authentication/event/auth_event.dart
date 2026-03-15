// Authentication Events
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String phoneNumber;
  final String password;

  const LoginEvent(this.phoneNumber, this.password);

  @override
  List<Object> get props => [phoneNumber, password];
}

class BiometricLoginEvent extends AuthEvent {
  const BiometricLoginEvent();
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;

  const VerifyOtpEvent(this.phoneNumber, this.otp);

  @override
  List<Object> get props => [phoneNumber, otp];
}

class CreateProfileEvent extends AuthEvent {
  final String fullName;
  final String phoneNumber;
  final String password;
  final String? email;

  const CreateProfileEvent(this.fullName, this.phoneNumber, this.password,
      {this.email});

  @override
  List<Object> get props => [fullName, phoneNumber, password, email ?? ''];
}

class LoadProfileEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final String fullName;

  const UpdateProfileEvent(this.fullName);

  @override
  List<Object> get props => [fullName];
}

class LoadWalletEvent extends AuthEvent {}

class FundWalletEvent extends AuthEvent {
  final double amount;

  const FundWalletEvent(this.amount);

  @override
  List<Object> get props => [amount];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class ResendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const ResendOtpEvent(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class UpdateProfilePictureEvent extends AuthEvent {
  final String imageFilePath;

  const UpdateProfilePictureEvent(this.imageFilePath);

  @override
  List<Object> get props => [imageFilePath];
}

class ChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordEvent(this.currentPassword, this.newPassword);

  @override
  List<Object> get props => [currentPassword, newPassword];
}
