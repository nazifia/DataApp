// Business Settings Page — owner-only form to edit branding, markups, fees
// and limits for their own tenant (PATCH /admin/settings/).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../event/admin_event.dart';
import '../state/admin_state.dart';
import '../../../core/constants/theme.dart';
import '../../../core/widgets/custom_text_field.dart';

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _populated = false;

  // Text fields rendered in order, grouped by section.
  static const _textFields = ['name', 'support_email', 'support_phone',
      'primary_color', 'logo_url'];
  static const _numberFields = [
    'airtime_markup_percent',
    'data_markup_percent',
    'bill_markup_percent',
    'referral_bonus',
    'min_wallet_fund',
    'min_withdrawal',
    'withdrawal_fee',
    'max_daily_transaction',
  ];

  static const _labels = {
    'name': 'Business Name',
    'support_email': 'Support Email',
    'support_phone': 'Support Phone',
    'primary_color': 'Brand Color (hex, e.g. #1976D2)',
    'logo_url': 'Logo URL',
    'airtime_markup_percent': 'Airtime Markup (%)',
    'data_markup_percent': 'Data Markup (%)',
    'bill_markup_percent': 'Bill Markup (%)',
    'referral_bonus': 'Referral Bonus (₦)',
    'min_wallet_fund': 'Min Wallet Funding (₦)',
    'min_withdrawal': 'Min Withdrawal (₦)',
    'withdrawal_fee': 'Withdrawal Fee (₦)',
    'max_daily_transaction': 'Max Daily Spend / User (₦)',
  };

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadSettingsEvent());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate(Map<String, dynamic> settings) {
    for (final key in [..._textFields, ..._numberFields]) {
      final value = settings[key];
      final text = value == null ? '' : value.toString();
      _controllers.putIfAbsent(key, () => TextEditingController()).text = text;
    }
    _populated = true;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final changes = <String, dynamic>{};
    for (final key in _textFields) {
      changes[key] = _controllers[key]?.text.trim() ?? '';
    }
    for (final key in _numberFields) {
      changes[key] = double.tryParse(_controllers[key]?.text.trim() ?? '') ?? 0;
    }
    FocusScope.of(context).unfocus();
    context.read<AdminBloc>().add(UpdateSettingsEvent(changes));
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  String? _numberValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Required';
    final n = double.tryParse(t);
    if (n == null) return 'Enter a valid number';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  String? _percentValidator(String? v) {
    final base = _numberValidator(v);
    if (base != null) return base;
    if (double.parse(v!.trim()) > 100) return 'Cannot exceed 100%';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is SettingsLoaded && state.justSaved) {
            _snack('Settings saved');
          } else if (state is SettingsSaveError) {
            _snack(state.message, error: true);
          } else if (state is AdminNotAuthorized) {
            _snack('Owner access only', error: true);
          }
        },
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminNotAuthorized) {
            return _notAuthorizedView();
          }
          if (state is AdminError) {
            return _errorView(state.message);
          }

          Map<String, dynamic>? settings;
          var saving = false;
          if (state is SettingsLoaded) {
            settings = state.settings;
          } else if (state is SettingsSaving) {
            settings = state.settings;
            saving = true;
          } else if (state is SettingsSaveError) {
            settings = state.settings;
          }
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_populated) _populate(settings);

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _sectionHeader('Branding'),
                    for (final key in _textFields) _field(key),
                    const SizedBox(height: 8),
                    _sectionHeader('Pricing & Markups'),
                    for (final key in [
                      'airtime_markup_percent',
                      'data_markup_percent',
                      'bill_markup_percent',
                    ])
                      _field(key, validator: _percentValidator),
                    _field('referral_bonus', validator: _numberValidator),
                    const SizedBox(height: 8),
                    _sectionHeader('Wallet & Limits'),
                    for (final key in [
                      'min_wallet_fund',
                      'min_withdrawal',
                      'withdrawal_fee',
                      'max_daily_transaction',
                    ])
                      _field(key, validator: _numberValidator),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _save,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(saving ? 'Saving…' : 'Save Changes',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (saving)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _field(String key, {String? Function(String?)? validator}) {
    final isNumber = _numberFields.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: _labels[key] ?? key,
        controller: _controllers[key],
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : (key == 'support_email'
                ? TextInputType.emailAddress
                : (key == 'support_phone'
                    ? TextInputType.phone
                    : TextInputType.text)),
        validator: validator,
      ),
    );
  }

  Widget _notAuthorizedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 48, color: AppColors.warning),
            const SizedBox(height: 12),
            const Text('Owner access only',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'This area is for business owners. Your account does not have admin access.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AdminBloc>().add(const LoadSettingsEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
