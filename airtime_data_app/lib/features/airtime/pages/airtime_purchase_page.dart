// Airtime Purchase Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/airtime_bloc.dart';
import '../event/airtime_event.dart';
import '../state/airtime_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';
import '../../../core/utils/contact_picker.dart';

class AirtimePurchasePage extends StatefulWidget {
  const AirtimePurchasePage({super.key});

  @override
  State<AirtimePurchasePage> createState() => _AirtimePurchasePageState();
}

class _AirtimePurchasePageState extends State<AirtimePurchasePage> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedNetwork = 'MTN';
  final _formKey = GlobalKey<FormState>();

  static const _quickAmounts = [100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0];

  static const _networkColors = {
    'MTN': AppColors.mtn,
    'Airtel': AppColors.airtel,
    'Glo': AppColors.glo,
    '9mobile': AppColors.nineMobile,
  };

  static const _networkIcons = {
    'MTN': Icons.signal_cellular_alt_rounded,
    'Airtel': Icons.signal_cellular_alt_2_bar_rounded,
    'Glo': Icons.signal_cellular_alt_1_bar_rounded,
    '9mobile': Icons.signal_cellular_connected_no_internet_0_bar_rounded,
  };

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _purchaseAirtime() async {
    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = _phoneController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0;

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Confirm Purchase',
        message:
            'You are about to buy ${CurrencyFormatter.formatNaira(amount)} $_selectedNetwork airtime for $phoneNumber.',
        confirmLabel: 'Buy Now',
        icon: Icons.shopping_cart_rounded,
      );

      if (confirmed != true || !mounted) return;

      context.read<AirtimeBloc>().add(PurchaseAirtimeEvent(
            network: _selectedNetwork,
            phoneNumber: phoneNumber,
            amount: amount,
          ));
    }
  }

  Future<void> _pickContact() async {
    final number = await ContactPicker.pickPhoneNumber(context);
    if (number != null && mounted) {
      setState(() => _phoneController.text = number);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buy Airtime'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AirtimeBloc, AirtimeState>(
        listener: (context, state) {
          if (state is AirtimeSuccess) {
            _showSuccessSheet(context, state);
          } else if (state is AirtimeFailure) {
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
          final isLoading = state is AirtimeLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Network Selection
                _sectionLabel('Select Network'),
                const SizedBox(height: 12),
                _buildNetworkCards(),
                const SizedBox(height: 24),

                // Phone Number
                _sectionLabel('Recipient Phone Number'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '080XXXXXXXX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts_rounded,
                          color: AppColors.primary),
                      tooltip: 'Pick from contacts',
                      onPressed: _pickContact,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (!Validators.isValidNigerianPhone(value)) {
                      return 'Enter a valid Nigerian phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Amount
                _sectionLabel('Amount'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        '₦',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (!Validators.isValidAmount(value)) {
                      return 'Enter a valid amount';
                    }
                    final amount = double.tryParse(value) ?? 0;
                    if (amount < 100) return 'Minimum amount is ₦100';
                    if (amount > AppConstants.maxSingleTransaction) {
                      return 'Maximum is ${CurrencyFormatter.formatNaira(AppConstants.maxSingleTransaction)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Quick amount chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amount) {
                    return GestureDetector(
                      onTap: () => setState(() {
                        _amountController.text = amount.toInt().toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _amountController.text ==
                                  amount.toInt().toString()
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _amountController.text ==
                                    amount.toInt().toString()
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatNaira(amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _amountController.text ==
                                    amount.toInt().toString()
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Purchase summary
                if (_amountController.text.isNotEmpty &&
                    _phoneController.text.isNotEmpty)
                  _buildSummaryCard(),

                const SizedBox(height: 16),

                CustomButton(
                  text: isLoading
                      ? 'Processing...'
                      : 'Buy $_selectedNetwork Airtime',
                  onPressed: isLoading ? null : _purchaseAirtime,
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

  Widget _buildNetworkCards() {
    final networks = AppConstants.supportedNetworks;
    return Row(
      children: networks.asMap().entries.map((entry) {
        final i = entry.key;
        final network = entry.value;
        final isLast = i == networks.length - 1;
        final isSelected = _selectedNetwork == network;
        final color = _networkColors[network] ?? Colors.grey;
        final displayColor =
            color == AppColors.mtn ? Colors.amber[800]! : color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedNetwork = network),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: isLast ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _networkIcons[network] ?? Icons.signal_cellular_alt,
                      color: displayColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    network,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? displayColor : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow('Network', _selectedNetwork),
          _summaryRow('Phone', _phoneController.text),
          _summaryRow('Amount', CurrencyFormatter.formatNaira(amount)),
        ],
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, AirtimeSuccess state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SuccessSheet(
        title: 'Airtime Sent!',
        network: state.network,
        phone: state.phoneNumber,
        amount: state.amount,
        reference: state.reference,
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final String title;
  final String network;
  final String phone;
  final double amount;
  final String reference;

  const _SuccessSheet({
    required this.title,
    required this.network,
    required this.phone,
    required this.amount,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              child:
                  const Icon(Icons.check_rounded, size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.formatNaira(amount),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            _row('Network', network),
            _row('Recipient', phone),
            _row('Reference', reference),
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
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
}
