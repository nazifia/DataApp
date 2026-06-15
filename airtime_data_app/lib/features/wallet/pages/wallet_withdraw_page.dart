// Wallet Withdrawal Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../data/wallet_repository.dart';
import '../event/wallet_event.dart';
import '../state/wallet_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';

/// Withdraw wallet funds to any Nigerian bank account (commercial + microfinance).
///
/// Uses its own scoped [WalletBloc] so the withdrawal-flow states do not collide
/// with the dashboard's wallet-balance bloc. Returns `true` via [Navigator.pop]
/// when a withdrawal succeeds so the caller can refresh the balance.
class WalletWithdrawPage extends StatelessWidget {
  final double currentBalance;
  const WalletWithdrawPage({super.key, required this.currentBalance});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletBloc(
        walletRepository: context.read<WalletRepository>(),
      )..add(const LoadBanksEvent()),
      child: _WithdrawView(currentBalance: currentBalance),
    );
  }
}

class _WithdrawView extends StatefulWidget {
  final double currentBalance;
  const _WithdrawView({required this.currentBalance});

  @override
  State<_WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<_WithdrawView> {
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _banks = [];
  Map<String, dynamic>? _selectedBank;
  String? _resolvedName;
  bool _resolving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  String? get _bankCode => _selectedBank?['code'] as String?;
  String? get _bankName => _selectedBank?['name'] as String?;

  void _maybeResolve() {
    final acct = _accountController.text.trim();
    if (acct.length == 10 && _bankCode != null) {
      setState(() {
        _resolvedName = null;
        _resolving = true;
      });
      context.read<WalletBloc>().add(
            ResolveAccountEvent(accountNumber: acct, bankCode: _bankCode!),
          );
    } else {
      setState(() {
        _resolvedName = null;
        _resolving = false;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_resolvedName == null) {
      _snack('Verify the bank account first.');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount > widget.currentBalance) {
      _snack('Amount exceeds your wallet balance.');
      return;
    }
    context.read<WalletBloc>().add(WithdrawEvent(
          amount: amount,
          bankCode: _bankCode!,
          bankName: _bankName!,
          accountNumber: _accountController.text.trim(),
          accountName: _resolvedName!,
        ));
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
    ));
  }

  Future<void> _pickBank() async {
    if (_banks.isEmpty) {
      _snack('Banks are still loading…');
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BankPickerSheet(banks: _banks),
    );
    if (selected != null) {
      setState(() => _selectedBank = selected);
      _maybeResolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw to Bank')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WalletBloc, WalletState>(
            listenWhen: (_, s) =>
                s is BanksLoaded || s is BanksLoadFailure,
            listener: (context, state) {
              if (state is BanksLoaded) {
                setState(() => _banks = state.banks);
              } else if (state is BanksLoadFailure) {
                _snack(state.message, color: AppColors.error);
              }
            },
          ),
          BlocListener<WalletBloc, WalletState>(
            listenWhen: (_, s) =>
                s is AccountResolved || s is AccountResolveFailure,
            listener: (context, state) {
              if (state is AccountResolved) {
                setState(() {
                  _resolvedName = state.accountName;
                  _resolving = false;
                });
              } else if (state is AccountResolveFailure) {
                setState(() {
                  _resolvedName = null;
                  _resolving = false;
                });
                _snack(state.message, color: AppColors.error);
              }
            },
          ),
          BlocListener<WalletBloc, WalletState>(
            listenWhen: (_, s) =>
                s is WithdrawSuccess || s is WithdrawFailure,
            listener: (context, state) {
              if (state is WithdrawSuccess) {
                _snack(state.message, color: AppColors.success);
                Navigator.of(context).pop(true);
              } else if (state is WithdrawFailure) {
                _snack(state.message, color: AppColors.error);
              }
            },
          ),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available balance
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Balance',
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatNaira(widget.currentBalance),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount
                  const Text('Amount',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      prefixText: '₦ ',
                      hintText: '0',
                      filled: true,
                    ),
                    validator: (v) {
                      final amt = double.tryParse(v?.trim() ?? '');
                      if (amt == null || amt <= 0) return 'Enter an amount';
                      if (amt > widget.currentBalance) {
                        return 'Exceeds balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bank
                  const Text('Bank',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickBank,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(filled: true),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _bankName ?? 'Select bank',
                              style: TextStyle(
                                fontSize: 15,
                                color: _bankName == null
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account number
                  const Text('Account Number',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _maybeResolve(),
                    decoration: const InputDecoration(
                      hintText: '10-digit account number',
                      filled: true,
                      counterText: '',
                    ),
                    validator: (v) {
                      if ((v?.trim().length ?? 0) != 10) {
                        return 'Enter a valid 10-digit account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Resolved account name
                  if (_resolving)
                    Row(
                      children: const [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Verifying account…',
                            style: TextStyle(fontSize: 13)),
                      ],
                    )
                  else if (_resolvedName != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _resolvedName!,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Submit
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, state) {
                      final processing = state is WithdrawProcessing;
                      return CustomButton(
                        text: 'Withdraw',
                        isLoading: processing,
                        onPressed: processing ? null : _submit,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Searchable bank picker ──────────────────────────────────────────────────

class _BankPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> banks;
  const _BankPickerSheet({required this.banks});

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _query.isEmpty
        ? widget.banks
        : widget.banks
            .where((b) => (b['name'] as String)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search bank...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No bank found for "$_query"',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bank = filtered[index];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(bank['name'] as String,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.of(context).pop(bank),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
