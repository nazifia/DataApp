// Authentication Events
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
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
  final String? email;

  const CreateProfileEvent(this.fullName, this.phoneNumber, {this.email});

  @override
  List<Object> get props => [fullName, phoneNumber, email ?? ''];
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