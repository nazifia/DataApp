// Phone Input / Login Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../bloc/auth_bloc.dart';
import '../event/auth_event.dart';
import '../state/auth_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validation.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/contact_picker.dart';
import '../../../core/config/app_env.dart';

class PhoneInputPage extends StatefulWidget {
  final bool isLogin;

  const PhoneInputPage({super.key, required this.isLogin});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  bool _passwordVisible = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLogin) {
      _checkBiometric();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      final biometricEnabledValue =
          await _storage.read(key: 'biometric_enabled');
      if (mounted) {
        setState(() {
          _biometricAvailable = canCheck;
          _biometricEnabled = biometricEnabledValue == 'true';
        });
      }
    } catch (_) {}
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      final phone =
          Validators.formatNigerianPhone(_phoneController.text.trim());
      final password = _passwordController.text;
      context.read<AuthBloc>().add(LoginEvent(phone, password));
    }
  }

  void _biometricLogin() {
    context.read<AuthBloc>().add(const BiometricLoginEvent());
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final raw = _phoneController.text.trim();
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

  Future<void> _showEnableBiometricDialog(BuildContext ctx) async {
    final enable = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Enable Biometrics'),
          ],
        ),
        content: const Text(
          'Use fingerprint or face recognition to sign in faster next time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (enable == true && mounted) {
      final phone =
          Validators.formatNigerianPhone(_phoneController.text.trim());
      await _storage.write(key: 'biometric_enabled', value: 'true');
      await _storage.write(key: 'biometric_phone', value: phone);
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
          if (state is LoginSuccess) {
            final navigator = Navigator.of(context);
            if (_biometricAvailable && !_biometricEnabled) {
              _showEnableBiometricDialog(context).then((_) {
                if (mounted) {
                  navigator.pushNamedAndRemoveUntil('/dashboard', (r) => false);
                }
              });
            } else {
              navigator.pushNamedAndRemoveUntil('/dashboard', (r) => false);
            }
          } else if (state is OtpSuccess) {
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
          return widget.isLogin
              ? _buildLoginForm(isLoading)
              : _buildRegisterForm(isLoading);
        },
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to your TopUpNaija account',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Dev mode hint
            if (AppConfig.dev.useMockAuth) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bug_report_rounded,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Dev mode — Password: password123',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Phone Number
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              decoration: InputDecoration(
                hintText: '0XXXXXXXXXX or +234XXXXXXXXX',
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
                        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
                if (!Validators.isValidNigerianPhone(cleaned)) {
                  return 'Enter a valid Nigerian number (e.g. 08031234567 or +2348031234567)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sign In button
            CustomButton(
              text: 'Sign In',
              onPressed: isLoading ? null : _login,
              isLoading: isLoading,
            ),

            // Biometric button
            if (_biometricAvailable && _biometricEnabled) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _biometricLogin,
                icon: const Icon(Icons.fingerprint, size: 22),
                label: const Text('Sign in with Biometrics'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Toggle to register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed(
                      '/phone-input',
                      arguments: false,
                    );
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(
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
  }

  Widget _buildRegisterForm(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Join TopUpNaija',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Nigerian phone number to get started',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              decoration: InputDecoration(
                hintText: '0XXXXXXXXXX or +234XXXXXXXXX',
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
                        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
                if (!Validators.isValidNigerianPhone(cleaned)) {
                  return 'Enter a valid Nigerian number (e.g. 08031234567 or +2348031234567)';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              'e.g. 08031234567 — MTN, Airtel, Glo, 9mobile',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 36),

            CustomButton(
              text: 'Continue',
              onPressed: isLoading ? null : _sendOtp,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed(
                      '/phone-input',
                      arguments: true,
                    );
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
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
  }
}
