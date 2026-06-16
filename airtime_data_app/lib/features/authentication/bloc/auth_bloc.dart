// Authentication Bloc
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/validation.dart';
import '../../../core/utils/api_error.dart';
import '../event/auth_event.dart';
import '../state/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

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
      // Explicit workspace wins; otherwise login falls back to the persisted
      // slug (api_client). Validate before login so a wrong slug fails clearly.
      if (event.tenantSlug != null && event.tenantSlug!.isNotEmpty) {
        await _authRepository.validateAndSetTenant(event.tenantSlug!);
      }
      await _authRepository.login(event.phoneNumber, event.password);
      emit(const LoginSuccess());
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
    }
  }

  Future<void> _onBiometricLogin(
      BiometricLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      if (!await BiometricService.isBiometricEnabled()) {
        emit(const AuthFailure('Biometric login is not set up'));
        return;
      }
      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to sign in to TopUpNaija',
      );
      if (!authenticated) {
        emit(const AuthFailure('Biometric authentication failed'));
        return;
      }
      // Identity verified locally — exchange the stored credential for a live
      // session before treating the user as logged in.
      await _authRepository.biometricLogin();
      emit(const LoginSuccess());
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
    }
  }

  Future<void> _onSendOtp(
      SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      if (event.tenantSlug != null && event.tenantSlug!.isNotEmpty) {
        await _authRepository.validateAndSetTenant(event.tenantSlug!);
      }
      await _authRepository.sendOtp(event.phoneNumber);
      emit(const OtpSuccess('OTP sent successfully'));
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
    }
  }

  Future<void> _onVerifyOtp(
      VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(const OtpLoading());
    try {
      final data = await _authRepository.verifyOtp(event.phoneNumber, event.otp);
      final isNewUser = data['is_new_user'] as bool? ?? true;
      emit(OtpVerified(isNewUser: isNewUser));
    } catch (e) {
      emit(OtpVerificationFailed(extractApiError(e)));
    }
  }

  Future<void> _onCreateProfile(
      CreateProfileEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.createProfile(
          event.phoneNumber, event.fullName, event.password, email: event.email);
      emit(AuthSuccess(
        userId: response['user']['id'].toString(),
        phoneNumber: Validators.formatNigerianPhone(event.phoneNumber),
        fullName: event.fullName,
        email: event.email,
        profilePicture: response['user']['profile_picture_url']?.toString(),
      ));
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
    }
  }

  Future<void> _onLoadProfile(
      LoadProfileEvent event, Emitter<AuthState> emit) async {
    emit(const ProfileLoading());
    try {
      final response = await _authRepository.getProfile();
      emit(ProfileSuccess(Map<String, dynamic>.from(response['user'] as Map)));
    } catch (e) {
      emit(ProfileFailure(extractApiError(e)));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.updateProfile(event.fullName, email: event.email);
      add(LoadProfileEvent());
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
    }
  }

  Future<void> _onLoadWallet(
      LoadWalletEvent event, Emitter<AuthState> emit) async {
    emit(const WalletLoading());
    try {
      final response = await _authRepository.getWalletBalance();
      emit(WalletSuccess((response['balance'] as num).toDouble()));
    } catch (e) {
      emit(WalletFailure(extractApiError(e)));
    }
  }

  Future<void> _onFundWallet(
      FundWalletEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.fundWallet(event.amount);
      add(LoadWalletEvent());
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
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
      add(LoadProfileEvent());
    } catch (e) {
      emit(AuthFailure(extractApiError(e)));
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
      emit(PasswordChangedFailure(extractApiError(e)));
    }
  }
}
