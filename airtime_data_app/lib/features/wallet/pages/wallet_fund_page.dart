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

class WalletFundPage extends StatefulWidget {
  const WalletFundPage({super.key});

  @override
  State<WalletFundPage> createState() => _WalletFundPageState();
}

class _WalletFundPageState extends State<WalletFundPage> {
  final _amountController = TextEditingController();
  int _selectedGatewayIndex = 0;
  final _formKey = GlobalKey<FormState>();

  static const _quickAmounts = [1000.0, 2000.0, 5000.0, 10000.0, 20000.0, 50000.0];

  static const _gateways = [
    _GatewayOption(
      name: 'Paystack',
      icon: Icons.credit_card_rounded,
      color: AppColors.info,
      description: 'Pay with card or bank',
    ),
    _GatewayOption(
      name: 'Flutterwave',
      icon: Icons.account_balance_rounded,
      color: Colors.orange,
      description: 'Card, bank & mobile',
    ),
    _GatewayOption(
      name: 'Bank Transfer',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.primary,
      description: 'Direct bank transfer',
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fundWallet() async {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final method = _gateways[_selectedGatewayIndex].name;

      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Confirm Funding',
        message:
            'You are about to fund your wallet with ${CurrencyFormatter.formatNaira(amount)} via $method.',
        confirmLabel: 'Fund Now',
        icon: Icons.account_balance_wallet_rounded,
      );

      if (confirmed != true || !mounted) return;

      context.read<WalletBloc>().add(FundWalletEvent(amount));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fund Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletSuccess) {
            _showSuccessSheet(context, state.balance);
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
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 14),
                      const Expanded(
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
                const Text(
                  'Enter Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      color: Colors.grey[300],
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                      child: Text(
                        '₦',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatNairaCompact(amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Payment method
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._gateways.asMap().entries.map((entry) {
                  final i = entry.key;
                  final gw = entry.value;
                  final isSelected = _selectedGatewayIndex == i;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedGatewayIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? gw.color.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? gw.color : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: gw.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(gw.icon, color: gw.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gw.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  gw.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: gw.color, size: 22)
                          else
                            Icon(Icons.radio_button_unchecked_rounded,
                                color: Colors.grey[300], size: 22),
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
                        const Text('Summary',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        _summaryRow('Amount',
                            CurrencyFormatter.formatNaira(double.tryParse(_amountController.text) ?? 0)),
                        _summaryRow('Method', _gateways[_selectedGatewayIndex].name),
                        _summaryRow('Destination', 'Your Wallet'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                CustomButton(
                  text: isLoading ? 'Processing...' : 'Fund Wallet',
                  onPressed: isLoading ? null : _fundWallet,
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, double newBalance) {
    final amount = double.tryParse(_amountController.text) ?? 0;
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                  'Method', _gateways[_selectedGatewayIndex].name),
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

class _GatewayOption {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const _GatewayOption({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
