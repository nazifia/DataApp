// Data Purchase Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/data_bloc.dart';
import '../event/data_event.dart';
import '../state/data_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';
import '../../../core/utils/contact_picker.dart';

class DataPurchasePage extends StatefulWidget {
  const DataPurchasePage({super.key});

  @override
  State<DataPurchasePage> createState() => _DataPurchasePageState();
}

class _DataPurchasePageState extends State<DataPurchasePage> {
  final _phoneController = TextEditingController();
  String _selectedNetwork = 'MTN';
  String _selectedPlanId = '';
  String _selectedPlanName = '';
  double _selectedPlanPrice = 0;
  final _formKey = GlobalKey<FormState>();

  static const _networkColors = {
    'MTN': AppColors.mtn,
    'Airtel': AppColors.airtel,
    'Glo': AppColors.glo,
    '9mobile': AppColors.nineMobile,
  };

  @override
  void initState() {
    super.initState();
    _loadDataPlans();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _loadDataPlans() {
    context.read<DataBloc>().add(DataEvent.loadDataPlans(_selectedNetwork));
  }

  Future<void> _purchaseData() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedPlanId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a data plan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Confirm Purchase',
        message:
            'You are about to buy $_selectedPlanName on $_selectedNetwork for ${_phoneController.text.trim()} at ${CurrencyFormatter.formatNaira(_selectedPlanPrice)}.',
        confirmLabel: 'Buy Now',
        icon: Icons.shopping_cart_rounded,
      );

      if (confirmed != true || !mounted) return;

      context.read<DataBloc>().add(DataEvent.purchaseData(
            network: _selectedNetwork,
            planId: _selectedPlanId,
            phoneNumber: _phoneController.text.trim(),
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
        title: const Text('Buy Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<DataBloc, DataState>(
        listener: (context, state) {
          if (state is DataSuccess) {
            _showSuccessSheet(context, state);
          } else if (state is DataFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is DataPlansFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DataLoading || state is DataPlansLoading;

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

                // Data Plans
                _sectionLabel('Available Data Plans'),
                const SizedBox(height: 12),
                _buildDataPlansSection(state),
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

                // Summary
                if (_selectedPlanId.isNotEmpty &&
                    _phoneController.text.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                ],

                const SizedBox(height: 32),
                CustomButton(
                  text: isLoading
                      ? 'Processing...'
                      : 'Buy Data Plan',
                  onPressed: isLoading ? null : _purchaseData,
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
    return Row(
      children: AppConstants.supportedNetworks.asMap().entries.map((entry) {
        final network = entry.value;
        final isLast = entry.key == AppConstants.supportedNetworks.length - 1;
        final isSelected = _selectedNetwork == network;
        final color = _networkColors[network] ?? Colors.grey;
        final displayColor =
            color == AppColors.mtn ? Colors.amber[800]! : color;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedNetwork = network;
                _selectedPlanId = '';
                _selectedPlanName = '';
                _selectedPlanPrice = 0;
              });
              _loadDataPlans();
            },
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wifi_rounded,
                        color: displayColor, size: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    network,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildDataPlansSection(DataState state) {
    if (state is DataPlansLoading) {
      return _buildShimmerPlans();
    } else if (state is DataPlansSuccess) {
      if (state.plans.isEmpty) {
        return _buildNoPlans();
      }
      return _buildPlansList(state.plans);
    } else if (state is DataPlansFailure) {
      return _buildErrorPlans(state.message);
    }
    return _buildShimmerPlans();
  }

  Widget _buildShimmerPlans() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }

  Widget _buildNoPlans() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              'No plans available for $_selectedNetwork',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlans(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: Colors.red[300]),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[400]),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadDataPlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(List<Map<String, dynamic>> plans) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isSelected = plan['id'] == _selectedPlanId &&
            plan['network'] == _selectedNetwork;
        final color =
            _networkColors[_selectedNetwork] ?? AppColors.primary;
        final displayColor =
            color == AppColors.mtn ? Colors.amber[800]! : color;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPlanId = plan['id'] as String;
              _selectedPlanName = plan['name'] as String;
              _selectedPlanPrice =
                  double.tryParse(plan['price'].toString()) ?? 0;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Plan icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? displayColor.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.data_usage_rounded,
                    color: isSelected ? displayColor : Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (plan['name'] as String?) ?? 'Unknown Plan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            plan['data'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (plan['validity'] != null) ...[
                            const Text(' • ',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            Text(
                              plan['validity'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatNaira(
                          double.tryParse(plan['price'].toString()) ?? 0),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? displayColor : AppColors.textPrimary,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
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
          const Text('Summary',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          _summaryRow('Network', _selectedNetwork),
          _summaryRow('Plan', _selectedPlanName),
          _summaryRow('Phone', _phoneController.text),
          _summaryRow('Amount', CurrencyFormatter.formatNaira(_selectedPlanPrice)),
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

  void _showSuccessSheet(BuildContext context, DataSuccess state) {
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
              const Text('Data Activated!',
                  style: TextStyle(
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
              _detailRow('Network', state.network),
              _detailRow('Plan', state.planName),
              _detailRow('Volume', state.data),
              _detailRow('Validity', state.validity),
              _detailRow('Recipient', state.phoneNumber),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
