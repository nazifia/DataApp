// Business / Tenant Registration Page — public self-service signup.
// Creates a new workspace (tenant), then routes the owner to create their
// account under it. Self-contained: manages its own loading state via the
// AuthRepository instead of AuthBloc, since this is a one-shot form.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validation.dart';
import '../../../core/constants/theme.dart';

class BusinessRegistrationPage extends StatefulWidget {
  const BusinessRegistrationPage({super.key});

  @override
  State<BusinessRegistrationPage> createState() =>
      _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState extends State<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _supportPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final repo = context.read<AuthRepository>();
    try {
      final result = await repo.registerTenant(
        name: _nameController.text.trim(),
        ownerEmail: _emailController.text.trim(),
        ownerPhone: _phoneController.text.trim(),
        ownerPassword: _passwordController.text,
        slug: _slugController.text.trim(),
        supportPhone: _supportPhoneController.text.trim(),
      );
      if (!mounted) return;
      final slug = result['slug']?.toString() ?? '';
      _showSuccess(slug);
    } on DioException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Registration failed. Please try again.');
    } catch (_) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showSuccess(String slug) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Workspace Created')),
          ],
        ),
        content: Text(
          'Your workspace is live. Your workspace slug is "$slug" — share it '
          'with your team so they can join.\n\nSign in with your owner phone '
          'and the password you just set.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Owner account is already provisioned with the chosen password,
              // and the new slug is persisted — route straight to password sign-in.
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/phone-input',
                (r) => r.settings.name == '/welcome' || r.isFirst,
                arguments: true,
              );
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          'Register Your Business',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Launch your workspace',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up a branded VTU workspace for your business. '
                'You can fine-tune pricing and limits later.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              _label('Business Name *'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Acme Telecom',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your business name';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _label('Workspace Slug (optional)'),
              TextFormField(
                controller: _slugController,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'e.g. acme — leave blank to auto-generate',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 2) {
                    return 'Slug must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Your team uses this to join your workspace.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),

              _label('Owner Email *'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'owner@business.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter the owner email';
                  }
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(v.trim());
                  return ok ? null : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 20),

              _label('Owner Phone *'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: const InputDecoration(
                  hintText: '0XXXXXXXXXX or +234XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: _phoneValidator,
              ),
              const SizedBox(height: 20),

              _label('Owner Password *'),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setState(
                        () => _passwordVisible = !_passwordVisible),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please set an owner password';
                  }
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'You sign in with your owner phone and this password.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),

              _label('Support Phone (optional)'),
              TextFormField(
                controller: _supportPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Shown to your customers for help',
                  prefixIcon: Icon(Icons.support_agent_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return _phoneValidator(v);
                },
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Create Workspace',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'By continuing you agree to operate within Nigerian VTU regulations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
    if (!Validators.isValidNigerianPhone(cleaned)) {
      return 'Enter a valid Nigerian number (e.g. 08031234567)';
    }
    return null;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
}
