// Authentication Bloc
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/validation.dart';
import '../event/auth_event.dart';
import '../state/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<BiometricLoginEvent>(_onBiometricLogin);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CreateProfileEvent>(_onCreateProfile);
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LoadWalletEvent>(_onLoadWallet);
    on<FundWalletEvent>(_onFundWallet);
    on<LogoutEvent>(_onLogout);
    on<ResendOtpEvent>(_onResendOtp);
    on<UpdateProfilePictureEvent>(_onUpdateProfilePicture);
    on<ChangePasswordEvent>(_onChangePassword);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.login(event.phoneNumber, event.password);
      emit(const LoginSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onBiometricLogin(
      BiometricLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final canAuth = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuth) {
        emit(const AuthFailure('Biometric authentication not available'));
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in to ADP Nigeria',
      );
      if (authenticated) {
        emit(const LoginSuccess());
      } else {
        emit(const AuthFailure('Biometric authentication failed'));
      }
    } catch (e) {
      emit(AuthFailure('Biometric error: $e'));
    }
  }

  Future<void> _onSendOtp(
      SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendOtp(event.phoneNumber);
      emit(const OtpSuccess('OTP sent successfully'));
    } catch (e) {
      emit(AuthFailure('Failed to send OTP: $e'));
    }
  }

  Future<void> _onVerifyOtp(
      VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(const OtpLoading());
    try {
      await _authRepository.verifyOtp(event.phoneNumber, event.otp);
      emit(const OtpVerified());
    } catch (e) {
      emit(OtpVerificationFailed('Invalid OTP: $e'));
    }
  }

  Future<void> _onCreateProfile(
      CreateProfileEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.createProfile(
          event.phoneNumber, event.fullName, event.password);
      emit(AuthSuccess(
        userId: response['user']['id'].toString(),
        phoneNumber: Validators.formatNigerianPhone(event.phoneNumber),
        fullName: event.fullName,
        profilePicture: response['user']['profile_picture']?.toString(),
      ));
    } catch (e) {
      emit(AuthFailure('Failed to create profile: $e'));
    }
  }

  Future<void> _onLoadProfile(
      LoadProfileEvent event, Emitter<AuthState> emit) async {
    emit(const ProfileLoading());
    try {
      final response = await _authRepository.getProfile();
      emit(ProfileSuccess(Map<String, dynamic>.from(response['user'] as Map)));
    } catch (e) {
      emit(ProfileFailure('Failed to load profile: $e'));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.updateProfile(event.fullName);
      emit(const AuthLoading()); // Reload to get updated data
      add(LoadProfileEvent());
    } catch (e) {
      emit(AuthFailure('Failed to update profile: $e'));
    }
  }

  Future<void> _onLoadWallet(
      LoadWalletEvent event, Emitter<AuthState> emit) async {
    emit(const WalletLoading());
    try {
      final response = await _authRepository.getWalletBalance();
      emit(WalletSuccess((response['balance'] as num).toDouble()));
    } catch (e) {
      emit(WalletFailure('Failed to load wallet: $e'));
    }
  }

  Future<void> _onFundWallet(
      FundWalletEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.fundWallet(event.amount);
      emit(const AuthLoading()); // Reload wallet balance
      add(LoadWalletEvent());
    } catch (e) {
      emit(AuthFailure('Failed to fund wallet: $e'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.clearTokens();
    emit(const AuthInitial());
  }

  Future<void> _onResendOtp(
      ResendOtpEvent event, Emitter<AuthState> emit) async {
    add(SendOtpEvent(event.phoneNumber));
  }

  Future<void> _onUpdateProfilePicture(
      UpdateProfilePictureEvent event, Emitter<AuthState> emit) async {
    emit(const ProfileLoading());
    try {
      await _authRepository.uploadProfilePicture(
        File(event.imageFilePath),
      );
      // Reload profile to get updated picture URL
      add(LoadProfileEvent());
    } catch (e) {
      emit(AuthFailure('Failed to upload profile picture: $e'));
    }
  }

  Future<void> _onChangePassword(
      ChangePasswordEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.changePassword(
          event.currentPassword, event.newPassword);
      emit(const PasswordChangedSuccess());
    } catch (e) {
      emit(PasswordChangedFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
