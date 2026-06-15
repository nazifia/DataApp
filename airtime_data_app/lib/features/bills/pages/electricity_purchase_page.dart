// Electricity Bill Payment Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bills_bloc.dart';
import '../event/bills_event.dart';
import '../state/bills_state.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/event/auth_event.dart';
import '../../authentication/state/auth_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/pin_input_dialog.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';

class ElectricityPurchasePage extends StatefulWidget {
  const ElectricityPurchasePage({super.key});

  @override
  State<ElectricityPurchasePage> createState() =>
      _ElectricityPurchasePageState();
}

class _ElectricityPurchasePageState extends State<ElectricityPurchasePage> {
  static const _category = 'electricity';

  final _formKey = GlobalKey<FormState>();
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  List<Map<String, dynamic>> _providers = [];
  String? _serviceId;
  String _meterType = 'prepaid'; // prepaid | postpaid
  String? _verifiedName;
  String _verifiedKey = ''; // serviceId|meter|type that was verified

  @override
  void initState() {
    super.initState();
    context.read<BillsBloc>().add(const LoadProvidersEvent(_category));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is ProfileSuccess) {
        _onProfileLoaded(authState.profileData);
      } else {
        context.read<AuthBloc>().add(LoadProfileEvent());
      }
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onProfileLoaded(Map<String, dynamic> profileData) {
    final raw = profileData['phone_number'] as String? ?? '';
    if (raw.isNotEmpty && _phoneController.text.isEmpty) {
      setState(() =>
          _phoneController.text = Validators.formatNigerianPhone(raw));
    }
  }

  String get _currentKey =>
      '$_serviceId|${_meterController.text.trim()}|$_meterType';

  bool get _isVerified =>
      _verifiedName != null && _verifiedKey == _currentKey;

  void _verify() {
    if (_serviceId == null) {
      _snack('Select an electricity provider first');
      return;
    }
    if (_meterController.text.trim().isEmpty) {
      _snack('Enter your meter number');
      return;
    }
    context.read<BillsBloc>().add(VerifyCustomerEvent(
          serviceId: _serviceId!,
          customerId: _meterController.text.trim(),
          variationCode: _meterType,
        ));
  }

  Future<void> _pay() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_serviceId == null) {
      _snack('Select an electricity provider');
      return;
    }
    if (!_isVerified) {
      _snack('Verify the meter number first');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Confirm Payment',
      message:
          'Pay ${CurrencyFormatter.formatNaira(amount)} for meter ${_meterController.text.trim()} ($_verifiedName)?',
      confirmLabel: 'Pay Now',
      icon: Icons.bolt_rounded,
    );
    if (confirmed != true || !mounted) return;

    final pinOk = await _verifyPin();
    if (!pinOk || !mounted) return;

    context.read<BillsBloc>().add(PayBillEvent(
          category: _category,
          serviceId: _serviceId!,
          customerId: _meterController.text.trim(),
          variationCode: _meterType,
          amount: amount,
          phoneNumber: _phoneController.text.trim(),
        ));
  }

  Future<bool> _verifyPin() async {
    final hasPin = await PinService.hasPin();
    if (!hasPin) return true;
    if (!mounted) return false;
    final entered = await PinInputDialog.show(context,
        subtitle: 'Confirm your transaction PIN');
    if (entered == null) return false;
    final valid = await PinService.verifyPin(entered);
    if (!valid && mounted) {
      _snack('Incorrect PIN. Transaction cancelled.', error: true);
    }
    return valid;
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileSuccess) _onProfileLoaded(state.profileData);
        },
        child: BlocConsumer<BillsBloc, BillsState>(
          listener: (context, state) {
            if (state is ProvidersSuccess) {
              setState(() => _providers = state.providers);
            } else if (state is CustomerVerified) {
              setState(() {
                _verifiedName = state.customerName;
                _verifiedKey = _currentKey;
              });
            } else if (state is CustomerVerifyFailed) {
              setState(() => _verifiedName = null);
              _snack(state.message, error: true);
            } else if (state is BillSuccess) {
              _showSuccessSheet(state);
            } else if (state is BillFailure) {
              _snack(state.message, error: true);
            } else if (state is ProvidersFailure) {
              _snack(state.message, error: true);
            }
          },
          builder: (context, state) {
            final verifying = state is CustomerVerifying;
            final paying = state is BillPaying;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _label('Distribution Company'),
                  const SizedBox(height: 10),
                  _providerDropdown(),
                  const SizedBox(height: 20),
                  _label('Meter Type'),
                  const SizedBox(height: 10),
                  _meterTypeToggle(),
                  const SizedBox(height: 20),
                  _label('Meter Number'),
                  const SizedBox(height: 10),
                  _meterField(verifying),
                  if (_isVerified) ...[
                    const SizedBox(height: 12),
                    _verifiedBanner(),
                  ],
                  const SizedBox(height: 20),
                  _label('Amount'),
                  const SizedBox(height: 10),
                  _amountField(),
                  const SizedBox(height: 20),
                  _label('Phone Number'),
                  const SizedBox(height: 10),
                  _phoneField(),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: paying ? 'Processing...' : 'Pay Bill',
                    onPressed: paying ? null : _pay,
                    isLoading: paying,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _providerDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _serviceId,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.bolt_rounded),
        hintText: 'Select provider',
      ),
      items: _providers
          .map((p) => DropdownMenuItem<String>(
                value: p['id'] as String,
                child: Text(p['name'] as String,
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (val) => setState(() {
        _serviceId = val;
        _verifiedName = null;
      }),
      validator: (val) => val == null ? 'Select a provider' : null,
    );
  }

  Widget _meterTypeToggle() {
    return Row(
      children: [
        _typeOption('Prepaid', 'prepaid'),
        const SizedBox(width: 12),
        _typeOption('Postpaid', 'postpaid'),
      ],
    );
  }

  Widget _typeOption(String label, String value) {
    final selected = _meterType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _meterType = value;
          _verifiedName = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meterField(bool verifying) {
    return TextFormField(
      controller: _meterController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_verifiedName != null) setState(() => _verifiedName = null);
      },
      decoration: InputDecoration(
        hintText: 'Enter meter number',
        prefixIcon: const Icon(Icons.tag_rounded),
        suffixIcon: verifying
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : TextButton(
                onPressed: _verify,
                child: const Text('Verify'),
              ),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Enter meter number' : null,
    );
  }

  Widget _verifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _verifiedName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        hintText: 'Enter amount',
        prefixIcon: Icon(Icons.payments_rounded),
        prefixText: '₦ ',
      ),
      validator: (v) {
        final amount = double.tryParse(v?.trim() ?? '') ?? 0;
        if (amount < 50) return 'Minimum amount is ₦50';
        return null;
      },
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      decoration: const InputDecoration(
        hintText: '0XXXXXXXXXX',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter phone number';
        if (!Validators.isValidNigerianPhone(v)) {
          return 'Enter a valid Nigerian phone number';
        }
        return null;
      },
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );

  void _showSuccessSheet(BillSuccess state) {
    final processing = state.status != 'success';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: (processing ? AppColors.warning : AppColors.success)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  processing ? Icons.hourglass_top_rounded : Icons.check_rounded,
                  size: 40,
                  color: processing ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(processing ? 'Payment Processing' : 'Payment Successful!',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.formatNaira(state.amount),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              if (state.token.isNotEmpty) _tokenCard(state.token),
              _detailRow('Meter', state.customerId),
              _detailRow('Provider', state.provider),
              _detailRow('Reference', state.reference),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tokenCard(String token) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('Recharge Token',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: SelectableText(
                  token,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy token',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  _snack('Token copied');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}
