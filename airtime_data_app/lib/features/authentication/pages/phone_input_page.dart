// Phone Input Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../event/auth_event.dart';
import '../state/auth_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validation.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/contact_picker.dart';

class PhoneInputPage extends StatefulWidget {
  final bool isLogin;

  const PhoneInputPage({super.key, required this.isLogin});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final raw = _phoneController.text.trim();
      // Normalize to local 11-digit format
      final phoneNumber = Validators.formatNigerianPhone(raw);
      context.read<AuthBloc>().add(SendOtpEvent(phoneNumber));
    }
  }

  Future<void> _pickContact() async {
    final number = await ContactPicker.pickPhoneNumber(context);
    if (number != null && mounted) {
      setState(() {
        _phoneController.text = Validators.formatNigerianPhone(number);
      });
    }
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
        title: Text(
          widget.isLogin ? 'Sign In' : 'Create Account',
          style: const TextStyle(
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
          if (state is OtpSuccess) {
            Navigator.of(context).pushNamed(
              '/otp-verification',
              arguments: {
                'phoneNumber': _phoneController.text.trim(),
                'isLogin': widget.isLogin,
              },
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading || state is OtpLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    widget.isLogin ? 'Welcome back!' : 'Join ADP Nigeria',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isLogin
                        ? 'Enter your registered phone number to continue'
                        : 'Enter your Nigerian phone number to get started',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Phone field label
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone number input with country code prefix
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '080XXXXXXXX',
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇳🇬', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '+234',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              width: 1,
                              height: 20,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.contacts_rounded,
                            color: AppColors.primary),
                        tooltip: 'Pick from contacts',
                        onPressed: _pickContact,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
                      // Accept both 11-digit (0xxx) and 10-digit (without leading 0)
                      if (!Validators.isValidNigerianPhone(cleaned) &&
                          !RegExp(r'^[789]\d{9}$').hasMatch(cleaned)) {
                        return 'Enter a valid Nigerian number (e.g. 08031234567)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'e.g. 08031234567 — MTN, Airtel, Glo, 9mobile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 36),

                  CustomButton(
                    text: widget.isLogin ? 'Send OTP' : 'Continue',
                    onPressed: isLoading ? null : _sendOtp,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Toggle between login/register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed(
                            '/phone-input',
                            arguments: !widget.isLogin,
                          );
                        },
                        child: Text(
                          widget.isLogin ? 'Register' : 'Sign In',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
