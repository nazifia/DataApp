// Agent sale page — sell airtime / data / electricity / TV to a customer.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/agents_bloc.dart';
import '../event/agents_event.dart';
import '../state/agents_state.dart';
import '../../data/data_repository.dart';
import '../../bills/data/bills_repository.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/pin_input_dialog.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';
import '../../../core/utils/api_error.dart';

const _networks = ['mtn', 'airtel', 'glo', 'etisalat'];

class AgentSalePage extends StatefulWidget {
  final double floatBalance;

  const AgentSalePage({super.key, required this.floatBalance});

  @override
  State<AgentSalePage> createState() => _AgentSalePageState();
}

class _AgentSalePageState extends State<AgentSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _customerIdController = TextEditingController();

  String _type = 'airtime';
  String? _network;

  // data
  List<Map<String, dynamic>> _plans = [];
  String? _planId;
  double _planPrice = 0;
  bool _plansLoading = false;

  // bills
  List<Map<String, dynamic>> _providers = [];
  String? _serviceId;
  bool _providersLoading = false;
  List<Map<String, dynamic>> _variations = [];
  String? _variationCode;
  double _variationAmount = 0;
  bool _variationsLoading = false;
  String _meterType = 'prepaid';

  late final DataRepository _dataRepo;
  late final BillsRepository _billsRepo;

  @override
  void initState() {
    super.initState();
    _dataRepo = context.read<DataRepository>();
    _billsRepo = context.read<BillsRepository>();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _customerIdController.dispose();
    super.dispose();
  }

  bool get _isBill => _type == 'electricity' || _type == 'tv';

  void _onTypeChanged(String t) {
    setState(() {
      _type = t;
      _network = null;
      _plans = [];
      _planId = null;
      _planPrice = 0;
      _providers = [];
      _serviceId = null;
      _variations = [];
      _variationCode = null;
      _variationAmount = 0;
      _amountController.clear();
      _customerIdController.clear();
    });
    if (_isBill) _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _providersLoading = true);
    try {
      final list = await _billsRepo.getProviders(_type);
      if (mounted) setState(() => _providers = list);
    } catch (e) {
      if (mounted) _snack(extractApiError(e), error: true);
    } finally {
      if (mounted) setState(() => _providersLoading = false);
    }
  }

  Future<void> _loadPlans(String network) async {
    setState(() {
      _plansLoading = true;
      _plans = [];
      _planId = null;
      _planPrice = 0;
    });
    try {
      final data = await _dataRepo.getDataPlans(network);
      final list = (data['plans'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _plans = list);
    } catch (e) {
      if (mounted) _snack(extractApiError(e), error: true);
    } finally {
      if (mounted) setState(() => _plansLoading = false);
    }
  }

  Future<void> _loadVariations(String serviceId) async {
    setState(() {
      _variationsLoading = true;
      _variations = [];
      _variationCode = null;
      _variationAmount = 0;
    });
    try {
      final list = await _billsRepo.getVariations(_type, serviceId);
      if (mounted) setState(() => _variations = list);
    } catch (e) {
      if (mounted) _snack(extractApiError(e), error: true);
    } finally {
      if (mounted) setState(() => _variationsLoading = false);
    }
  }

  double get _saleAmount {
    if (_type == 'data') return _planPrice;
    if (_type == 'tv') return _variationAmount;
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
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
      _snack('Incorrect PIN. Sale cancelled.', error: true);
    }
    return valid;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_type != 'electricity' && _type != 'tv' && _network == null) {
      _snack('Select a network');
      return;
    }
    if (_type == 'data' && _planId == null) {
      _snack('Select a data plan');
      return;
    }
    if (_isBill && _serviceId == null) {
      _snack('Select a provider');
      return;
    }
    if (_type == 'tv' && _variationCode == null) {
      _snack('Select a package');
      return;
    }
    final amount = _saleAmount;
    if (amount < 50) {
      _snack('Amount must be at least ₦50');
      return;
    }
    if (amount > widget.floatBalance) {
      _snack('Insufficient float balance', error: true);
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Confirm Sale',
      message:
          'Sell ${CurrencyFormatter.formatNaira(amount)} of $_type to ${_phoneController.text.trim()}? This is charged to your float.',
      confirmLabel: 'Sell Now',
      icon: Icons.point_of_sale_rounded,
    );
    if (confirmed != true || !mounted) return;

    final pinOk = await _verifyPin();
    if (!pinOk || !mounted) return;

    context.read<AgentsBloc>().add(MakeAgentSaleEvent(
          type: _type,
          phoneNumber: _phoneController.text.trim(),
          network: _network ?? '',
          planId: _planId ?? '',
          amount: _type == 'data' ? null : amount,
          serviceId: _serviceId ?? '',
          customerId: _isBill ? _customerIdController.text.trim() : '',
          variationCode:
              _type == 'tv' ? (_variationCode ?? '') : (_isBill ? _meterType : ''),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AgentsBloc, AgentsState>(
        listener: (context, state) {
          if (state is AgentSaleSuccess) {
            _showSuccessSheet(state);
          } else if (state is AgentSaleFailure) {
            _snack(state.message, error: true);
          }
        },
        builder: (context, state) {
          final selling = state is AgentSelling;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _floatPill(),
                const SizedBox(height: 20),
                _label('Product'),
                const SizedBox(height: 10),
                _typeSelector(),
                const SizedBox(height: 20),
                if (_type == 'airtime' || _type == 'data') ...[
                  _label('Network'),
                  const SizedBox(height: 10),
                  _networkChips(),
                  const SizedBox(height: 20),
                ],
                if (_type == 'data') ...[
                  _label('Data Plan'),
                  const SizedBox(height: 10),
                  _planDropdown(),
                  const SizedBox(height: 20),
                ],
                if (_isBill) ...[
                  _label(_type == 'tv' ? 'TV Provider' : 'Distribution Company'),
                  const SizedBox(height: 10),
                  _providerDropdown(),
                  const SizedBox(height: 20),
                ],
                if (_type == 'electricity') ...[
                  _label('Meter Type'),
                  const SizedBox(height: 10),
                  _meterTypeToggle(),
                  const SizedBox(height: 20),
                ],
                if (_type == 'tv') ...[
                  _label('Package'),
                  const SizedBox(height: 10),
                  _packageDropdown(),
                  const SizedBox(height: 20),
                ],
                if (_isBill) ...[
                  _label(_type == 'tv'
                      ? 'Smartcard / IUC Number'
                      : 'Meter Number'),
                  const SizedBox(height: 10),
                  _customerIdField(),
                  const SizedBox(height: 20),
                ],
                if (_type == 'airtime' || _type == 'electricity') ...[
                  _label('Amount'),
                  const SizedBox(height: 10),
                  _amountField(),
                  const SizedBox(height: 20),
                ],
                _label('Customer Phone'),
                const SizedBox(height: 10),
                _phoneField(),
                const SizedBox(height: 32),
                CustomButton(
                  text: selling ? 'Processing...' : 'Sell Now',
                  isLoading: selling,
                  onPressed: selling ? null : _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _floatPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          const Text('Float balance',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(CurrencyFormatter.formatNaira(widget.floatBalance),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _typeSelector() {
    final types = [
      ('airtime', 'Airtime', Icons.call_rounded),
      ('data', 'Data', Icons.wifi_rounded),
      ('electricity', 'Electricity', Icons.bolt_rounded),
      ('tv', 'Cable TV', Icons.tv_rounded),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final selected = _type == t.$1;
        return GestureDetector(
          onTap: () => _onTypeChanged(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$3,
                    size: 18,
                    color: selected ? AppColors.primary : null),
                const SizedBox(width: 6),
                Text(t.$2,
                    style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.primary : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _networkChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _networks.map((n) {
        final selected = _network == n;
        return GestureDetector(
          onTap: () {
            setState(() => _network = n);
            if (_type == 'data') _loadPlans(n);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
            child: Text(n.toUpperCase(),
                style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : null)),
          ),
        );
      }).toList(),
    );
  }

  Widget _planDropdown() {
    if (_network == null) {
      return _hintBox('Select a network first');
    }
    if (_plansLoading) return _loadingBox('Loading plans...');
    return DropdownButtonFormField<String>(
      initialValue: _planId,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.wifi_rounded),
        hintText: 'Select plan',
      ),
      items: _plans.map((p) {
        final price = double.tryParse(p['price'].toString()) ?? 0;
        return DropdownMenuItem<String>(
          value: p['id'] as String,
          child: Text('${p['name']} — ${CurrencyFormatter.formatNaira(price)}',
              overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        final p = _plans.firstWhere((e) => e['id'] == val,
            orElse: () => {});
        setState(() {
          _planId = val;
          _planPrice = double.tryParse(p['price'].toString()) ?? 0;
        });
      },
      validator: (val) => val == null ? 'Select a plan' : null,
    );
  }

  Widget _providerDropdown() {
    if (_providersLoading) return _loadingBox('Loading providers...');
    return DropdownButtonFormField<String>(
      initialValue: _serviceId,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon:
            Icon(_type == 'tv' ? Icons.tv_rounded : Icons.bolt_rounded),
        hintText: 'Select provider',
      ),
      items: _providers
          .map((p) => DropdownMenuItem<String>(
                value: p['id'] as String,
                child: Text(p['name'] as String,
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (val) {
        setState(() => _serviceId = val);
        if (_type == 'tv' && val != null) _loadVariations(val);
      },
      validator: (val) => val == null ? 'Select a provider' : null,
    );
  }

  Widget _packageDropdown() {
    if (_serviceId == null) return _hintBox('Select a provider first');
    if (_variationsLoading) return _loadingBox('Loading packages...');
    return DropdownButtonFormField<String>(
      initialValue: _variationCode,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.list_alt_rounded),
        hintText: 'Select package',
      ),
      items: _variations.map((v) {
        final amount = double.tryParse(v['amount'].toString()) ?? 0;
        return DropdownMenuItem<String>(
          value: v['variation_code'] as String,
          child: Text('${v['name']} — ${CurrencyFormatter.formatNaira(amount)}',
              overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        final v = _variations.firstWhere((e) => e['variation_code'] == val,
            orElse: () => {});
        setState(() {
          _variationCode = val;
          _variationAmount = double.tryParse(v['amount'].toString()) ?? 0;
        });
      },
      validator: (val) => val == null ? 'Select a package' : null,
    );
  }

  Widget _meterTypeToggle() {
    Widget option(String label, String value) {
      final selected = _meterType == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _meterType = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
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
              child: Text(label,
                  style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : null)),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      option('Prepaid', 'prepaid'),
      const SizedBox(width: 12),
      option('Postpaid', 'postpaid'),
    ]);
  }

  Widget _customerIdField() {
    return TextFormField(
      controller: _customerIdController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: _type == 'tv'
            ? 'Enter smartcard number'
            : 'Enter meter number',
        prefixIcon: const Icon(Icons.tag_rounded),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
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
        if (v == null || v.trim().isEmpty) return 'Enter customer phone';
        if (!Validators.isValidNigerianPhone(v)) {
          return 'Enter a valid Nigerian phone number';
        }
        return null;
      },
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  Widget _hintBox(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(text,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
    );
  }

  Widget _loadingBox(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children: [
        const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Text(text),
      ]),
    );
  }

  void _showSuccessSheet(AgentSaleSuccess state) {
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
                  processing
                      ? Icons.hourglass_top_rounded
                      : Icons.check_rounded,
                  size: 40,
                  color: processing ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(processing ? 'Sale Processing' : 'Sale Successful!',
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
              _detailRow('Product', state.type),
              _detailRow('Customer', state.customerPhone),
              _detailRow('Reference', state.reference),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // sheet
                    Navigator.of(context).pop(); // sale page
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
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
