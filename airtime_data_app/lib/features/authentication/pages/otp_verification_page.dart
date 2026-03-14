// OTP Verification Page
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../event/auth_event.dart';
import '../state/auth_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validation.dart';
import '../../../core/config/app_env.dart';
import '../../../core/constants/theme.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final bool isLogin;

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.isLogin,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 120);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsRemaining = 0);
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  void _verifyOtp() {
    final otp = _otpValue;
    if (!Validators.isValidOtp(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
          VerifyOtpEvent(widget.phoneNumber, otp),
        );
  }

  void _resendOtp() {
    _startTimer();
    context.read<AuthBloc>().add(ResendOtpEvent(widget.phoneNumber));
    // Clear boxes
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpValue.length == 6) {
      // Auto-verify when all boxes are filled
      _verifyOtp();
    }
  }

  String _formatTimer() {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            if (widget.isLogin) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/dashboard', (route) => false);
            } else {
              Navigator.of(context).pushNamed(
                '/profile-setup',
                arguments: widget.phoneNumber,
              );
            }
          } else if (state is OtpVerificationFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            // Clear all boxes on failure
            for (final c in _controllers) {
              c.clear();
            }
            _focusNodes.first.requestFocus();
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading ||
              state is OtpLoading ||
              state is OtpVerified;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Lock icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Enter OTP Code',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dev mode hint
                if (AppConfig.dev.useMockAuth) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report_rounded,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Dev mode — Test OTP: ${AppConfig.dev.testOtp}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _buildOtpBox(i, isLoading)),
                ),

                const SizedBox(height: 36),

                CustomButton(
                  text: 'Verify OTP',
                  onPressed: isLoading ? null : _verifyOtp,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),

                // Resend section
                Center(
                  child: _secondsRemaining > 0
                      ? Column(
                          children: [
                            Text(
                              'Resend code in',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimer(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Text(
                              "Didn't receive the code?",
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: _resendOtp,
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpBox(int index, bool disabled) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !disabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: _controllers[index].text.isNotEmpty
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          // Handle paste of full OTP
          if (v.length > 1) {
            final digits = v.replaceAll(RegExp(r'\D'), '');
            for (int i = 0; i < 6 && i < digits.length; i++) {
              _controllers[i].text = digits[i];
            }
            _focusNodes[5].requestFocus();
            if (mounted) setState(() {});
            if (_otpValue.length == 6) _verifyOtp();
            return;
          }
          _onOtpDigitChanged(index, v);
          setState(() {});
        },
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
      ),
    );
  }
}
