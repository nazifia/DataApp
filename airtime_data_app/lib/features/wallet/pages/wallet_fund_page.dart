// Wallet Funding Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../event/wallet_event.dart';
import '../state/wallet_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';
import 'qr_scanner_page.dart';

class WalletFundPage extends StatefulWidget {
  const WalletFundPage({super.key});

  @override
  State<WalletFundPage> createState() => _WalletFundPageState();
}

class _WalletFundPageState extends State<WalletFundPage> {
  final _amountController = TextEditingController();
  int _selectedMethodIndex = 0;
  final _formKey = GlobalKey<FormState>();

  static const _quickAmounts = [
    1000.0,
    2000.0,
    5000.0,
    10000.0,
    20000.0,
    50000.0
  ];

  static const _paymentMethods = [
    _PaymentMethod(
      name: 'Card / Account',
      icon: Icons.credit_card_rounded,
      color: AppColors.info,
      description: 'Pay with debit/credit card',
    ),
    _PaymentMethod(
      name: 'Bank USSD',
      icon: Icons.dialpad_rounded,
      color: Colors.purple,
      description: 'Dial USSD code from your phone',
    ),
    _PaymentMethod(
      name: 'QR Code',
      icon: Icons.qr_code_scanner_rounded,
      color: AppColors.success,
      description: 'Scan a payment QR code',
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final method = _paymentMethods[_selectedMethodIndex];

    switch (_selectedMethodIndex) {
      case 0:
        // Card / Account
        await _showCardPaymentSheet(amount);
      case 1:
        // Bank USSD
        await _showUssdSheet(amount);
      case 2:
        // QR Code
        await _openQrScanner();
      default:
        // Fallback: use original wallet fund flow
        final confirmed = await ConfirmationDialog.show(
          context: context,
          title: 'Confirm Funding',
          message:
              'You are about to fund your wallet with ${CurrencyFormatter.formatNaira(amount)} via ${method.name}.',
          confirmLabel: 'Fund Now',
          icon: Icons.account_balance_wallet_rounded,
        );
        if (confirmed != true || !mounted) return;
        context.read<WalletBloc>().add(FundWalletEvent(amount));
    }
  }

  Future<void> _showCardPaymentSheet(double amount) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CardPaymentSheet(
        amount: amount,
        onPay: () {
          Navigator.of(ctx).pop();
          // Trigger wallet funding through WalletBloc
          context.read<WalletBloc>().add(FundWalletEvent(amount));
        },
      ),
    );
  }

  Future<void> _showUssdSheet(double amount) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _UssdSheet(amount: amount),
    );
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScannerPage(),
      ),
    );

    if (result != null && mounted) {
      // Show the scanned result and prompt confirmation
      final amount = double.tryParse(_amountController.text) ?? 0;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('QR Code Scanned'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scanned value:',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Amount: ${CurrencyFormatter.formatNaira(amount)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<WalletBloc>().add(FundWalletEvent(amount));
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is FundWalletSuccess) {
            _showSuccessSheet(context, state.balance, state.amount);
          } else if (state is WalletFailure) {
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
          final isLoading = state is WalletLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 32),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Money to Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Funds are available instantly',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Amount input
                Text(
                  'Enter Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                      child: Text(
                        '₦',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    filled: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (!Validators.isValidAmount(value)) {
                      return 'Enter a valid amount';
                    }
                    final amount = double.tryParse(value) ?? 0;
                    if (amount < AppConstants.minWalletAmount) {
                      return 'Minimum is ${CurrencyFormatter.formatNaira(AppConstants.minWalletAmount)}';
                    }
                    if (amount > AppConstants.maxWalletAmount) {
                      return 'Maximum is ${CurrencyFormatter.formatNaira(AppConstants.maxWalletAmount)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Quick amounts
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amount) {
                    final selected =
                        _amountController.text == amount.toInt().toString();
                    return GestureDetector(
                      onTap: () => setState(() {
                        _amountController.text = amount.toInt().toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatNairaCompact(amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Payment method selection
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ..._paymentMethods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final method = entry.value;
                  final isSelected = _selectedMethodIndex == i;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedMethodIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? method.color.withValues(alpha: 0.06)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? method.color
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  method.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(method.icon,
                                color: method.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  method.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: method.color, size: 22)
                          else
                            Icon(Icons.radio_button_unchecked_rounded,
                                color: Theme.of(context).colorScheme.outlineVariant, size: 22),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 28),

                // Summary
                if (_amountController.text.isNotEmpty &&
                    double.tryParse(_amountController.text) != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summary',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 10),
                        _summaryRow(
                            'Amount',
                            CurrencyFormatter.formatNaira(
                                double.tryParse(_amountController.text) ??
                                    0)),
                        _summaryRow('Method',
                            _paymentMethods[_selectedMethodIndex].name),
                        _summaryRow('Destination', 'Your Wallet'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                CustomButton(
                  text: isLoading
                      ? 'Processing...'
                      : _proceedButtonLabel(),
                  onPressed: isLoading ? null : _proceed,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  String _proceedButtonLabel() {
    switch (_selectedMethodIndex) {
      case 0:
        return 'Pay with Card';
      case 1:
        return 'Get USSD Code';
      case 2:
        return 'Scan QR Code';
      default:
        return 'Proceed';
    }
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, double newBalance, double amount) {
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
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              const Text('Wallet Funded!',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.formatNaira(amount),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              _summaryRow('New Balance',
                  CurrencyFormatter.formatNaira(newBalance)),
              _summaryRow(
                  'Method', _paymentMethods[_selectedMethodIndex].name),
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
}

// ─── Card Payment Sheet ────────────────────────────────────────────────────

class _CardPaymentSheet extends StatefulWidget {
  final double amount;
  final VoidCallback onPay;

  const _CardPaymentSheet({required this.amount, required this.onPay});

  @override
  State<_CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<_CardPaymentSheet> {
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.credit_card_rounded,
                          color: AppColors.info, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Payment',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Amount: ${CurrencyFormatter.formatNaira(widget.amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Card Number
                Text('Card Number',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0000 0000 0000 0000',
                    prefixIcon:
                        Icon(Icons.credit_card_rounded),
                    filled: true,
                  ),
                  validator: (v) {
                    if (v == null || v.replaceAll(' ', '').length < 16) {
                      return 'Enter a valid 16-digit card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expiry and CVV row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expiry Date',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _expiryCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryFormatter(),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'MM/YY',
                              prefixIcon: Icon(Icons.calendar_month_rounded),
                              filled: true,
                            ),
                            validator: (v) {
                              if (v == null || v.length < 5) {
                                return 'Invalid expiry';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CVV',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cvvCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: const InputDecoration(
                              hintText: '•••',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                              filled: true,
                            ),
                            validator: (v) {
                              if (v == null || v.length < 3) {
                                return 'Invalid CVV';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cardholder Name
                Text('Cardholder Name',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Name on card',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    filled: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'Enter cardholder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Security note
                Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Your card details are encrypted and secure',
                      style: TextStyle(
                          fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Pay button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onPay();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Pay ${CurrencyFormatter.formatNaira(widget.amount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── USSD Sheet ───────────────────────────────────────────────────────────

class _UssdSheet extends StatefulWidget {
  final double amount;

  const _UssdSheet({required this.amount});

  @override
  State<_UssdSheet> createState() => _UssdSheetState();
}

class _UssdSheetState extends State<_UssdSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static final _banks = [
    _BankUssd(name: 'GTBank', logo: Icons.account_balance_rounded,
        color: Color(0xFFFF6900)),
    _BankUssd(name: 'Access Bank', logo: Icons.account_balance_rounded,
        color: Color(0xFFFF6600)),
    _BankUssd(name: 'First Bank', logo: Icons.account_balance_rounded,
        color: Color(0xFF003087)),
    _BankUssd(name: 'Zenith Bank', logo: Icons.account_balance_rounded,
        color: Color(0xFFDC1F27)),
    _BankUssd(name: 'UBA', logo: Icons.account_balance_rounded,
        color: Color(0xFFFF0000)),
    _BankUssd(name: 'Fidelity Bank', logo: Icons.account_balance_rounded,
        color: Color(0xFF007A4D)),
    _BankUssd(name: 'FCMB', logo: Icons.account_balance_rounded,
        color: Color(0xFF00205B)),
  ];

  String _ussdCode(String bankName, int amountInt) {
    switch (bankName) {
      case 'GTBank':
        return '*737*$amountInt*1#';
      case 'Access Bank':
        return '*901*$amountInt#';
      case 'First Bank':
        return '*894*$amountInt#';
      case 'Zenith Bank':
        return '*966*$amountInt#';
      case 'UBA':
        return '*919*$amountInt#';
      case 'Fidelity Bank':
        return '*770*$amountInt#';
      case 'FCMB':
        return '*329*$amountInt#';
      default:
        return '#';
    }
  }

  void _showUssdCode(BuildContext context, String bankName) {
    final code = _ussdCode(bankName, widget.amount.toInt());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$bankName USSD'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dial this USSD code from your $bankName registered phone number:',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount: ${CurrencyFormatter.formatNaira(widget.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$code copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _banks
        : _banks
            .where((b) =>
                b.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dialpad_rounded,
                      color: Colors.purple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank USSD Payment',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Amount: ${CurrencyFormatter.formatNaira(widget.amount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search field
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search bank...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            // Bank list
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No bank found for "$_query"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              ...filtered.map((bank) {
                final code = _ussdCode(bank.name, widget.amount.toInt());
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bank.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(bank.logo, color: bank.color, size: 22),
                  ),
                  title: Text(
                    bank.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    code,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6)),
                  onTap: () => _showUssdCode(context, bank.name),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────

class _PaymentMethod {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const _PaymentMethod({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _BankUssd {
  final String name;
  final IconData logo;
  final Color color;

  const _BankUssd(
      {required this.name, required this.logo, required this.color});
}

// ─── Input Formatters ──────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length >= 2) {
      final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}
