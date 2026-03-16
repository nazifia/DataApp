// Transaction History Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_history_bloc.dart';
import '../event/transaction_history_event.dart';
import '../state/transaction_history_state.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['All', 'Airtime', 'Data', 'Wallet'];
  List<Map<String, dynamic>>? _lastTransactions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    context.read<TransactionHistoryBloc>().add(LoadTransactionHistoryEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterTransactions(
      List<Map<String, dynamic>> all, int tabIndex) {
    if (tabIndex == 0) return all;
    final typeMap = {
      1: 'airtime',
      2: 'data',
      3: 'wallet_fund',
    };
    final type = typeMap[tabIndex] ?? '';
    return all
        .where((t) =>
            (t['type']?.toString() ?? '').toLowerCase() == type)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context
                  .read<TransactionHistoryBloc>()
                  .add(RefreshTransactionHistoryEvent());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: BlocConsumer<TransactionHistoryBloc, TransactionHistoryState>(
        listener: (context, state) {
          if (state is TransactionHistoryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TransactionHistorySuccess) {
            _lastTransactions = state.transactions;
          }
          if (state is TransactionHistoryLoading) {
            return _buildShimmerHistory();
          } else if (state is TransactionHistorySuccess) {
            return _buildTabView(state.transactions);
          } else if (state is TransactionHistoryFailure) {
            return _buildErrorHistory(state.message);
          } else if (_lastTransactions != null) {
            // During reversal loading/failure keep showing the last list
            return _buildTabView(_lastTransactions!);
          } else {
            return _buildShimmerHistory();
          }
        },
      ),
    );
  }

  Widget _buildTabView(List<Map<String, dynamic>> transactions) {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_tabs.length, (i) {
        final filtered = _filterTransactions(transactions, i);
        if (filtered.isEmpty) return _buildEmptyHistory(i);
        return _buildTransactionList(filtered);
      }),
    );
  }

  Widget _buildShimmerHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.grey[200]),
                    const SizedBox(height: 6),
                    Container(
                        width: 100, height: 11, color: Colors.grey[200]),
                    const SizedBox(height: 4),
                    Container(
                        width: 80, height: 10, color: Colors.grey[200]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                      width: 70, height: 14, color: Colors.grey[200]),
                  const SizedBox(height: 6),
                  Container(
                      width: 50, height: 10, color: Colors.grey[200]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory(int tabIndex) {
    final label = tabIndex == 0
        ? 'transactions'
        : '${_tabs[tabIndex].toLowerCase()} transactions';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No $label yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your $label will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorHistory(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red[400]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context
                  .read<TransactionHistoryBloc>()
                  .add(RefreshTransactionHistoryEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in transactions) {
      final rawDate = t['created_at']?.toString();
      String dateKey = 'Unknown';
      if (rawDate != null) {
        try {
          final dt = DateTime.parse(rawDate);
          final now = DateTime.now();
          if (dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day) {
            dateKey = 'Today';
          } else if (dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day - 1) {
            dateKey = 'Yesterday';
          } else {
            dateKey = DateFormatter.formatDate(dt);
          }
        } catch (_) {
          dateKey = rawDate;
        }
      }
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...entry.value
                .map((t) => _buildTransactionItem(t)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  void _showTransactionDetails(
      BuildContext context, Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TransactionDetailSheet(transaction: transaction),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return InkWell(
      onTap: () => _showTransactionDetails(context, transaction),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _txColor(transaction['type']).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _txIcon(transaction['type']),
                color: _txColor(transaction['type']),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _txTitle(transaction['type']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (transaction['phone_number'] ??
                            transaction['reference'] ??
                            'N/A')
                        .toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction['created_at'] != null) ...[
                    const SizedBox(height: 2),
                    Builder(builder: (context) {
                      try {
                        return Text(
                          DateFormatter.formatDateTime(DateTime.parse(
                              transaction['created_at'].toString())),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        );
                      } catch (_) {
                        return const SizedBox();
                      }
                    }),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatNaira(
                      double.tryParse(
                              transaction['amount']?.toString() ?? '0') ??
                          0),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(transaction['status']),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(transaction['status'])
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction['status']?.toString().toUpperCase() ??
                        'UNKNOWN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(transaction['status']),
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

  Color _txColor(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime': return AppColors.primary;
      case 'data': return AppColors.info;
      case 'wallet_fund': return AppColors.warning;
      case 'refund': return Colors.purple;
      default: return AppColors.textSecondary;
    }
  }

  IconData _txIcon(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime': return Icons.call_rounded;
      case 'data': return Icons.wifi_rounded;
      case 'wallet_fund': return Icons.account_balance_wallet_rounded;
      case 'refund': return Icons.replay_rounded;
      default: return Icons.receipt_long_outlined;
    }
  }

  String _txTitle(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime': return 'Airtime Purchase';
      case 'data': return 'Data Purchase';
      case 'wallet_fund': return 'Wallet Funding';
      case 'refund': return 'Refund';
      default: return 'Transaction';
    }
  }

  Color _statusColor(dynamic status) {
    switch ((status?.toString() ?? '').toLowerCase()) {
      case 'success': return AppColors.success;
      case 'failed': return AppColors.error;
      case 'pending': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }
}

// ─── Transaction Detail Sheet ──────────────────────────────────────────────

class _TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionDetailSheet({required this.transaction});

  Color _typeColor(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime': return AppColors.primary;
      case 'data': return AppColors.info;
      case 'wallet_fund': return AppColors.warning;
      case 'refund': return Colors.purple;
      default: return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime': return Icons.call_rounded;
      case 'data': return Icons.wifi_rounded;
      case 'wallet_fund': return Icons.account_balance_wallet_rounded;
      case 'refund': return Icons.replay_rounded;
      default: return Icons.receipt_long_outlined;
    }
  }

  String _typeTitle(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime': return 'Airtime Purchase';
      case 'data': return 'Data Purchase';
      case 'wallet_fund': return 'Wallet Funding';
      case 'refund': return 'Refund';
      default: return 'Transaction';
    }
  }

  Color _statusColor(dynamic status) {
    switch ((status?.toString() ?? '').toLowerCase()) {
      case 'success': return AppColors.success;
      case 'failed': return AppColors.error;
      case 'pending': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'];
    final status = transaction['status'];
    final isReversed = transaction['is_reversed'] == true;
    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final reference = (transaction['reference'] ?? 'N/A').toString();
    final createdAt = transaction['created_at']?.toString();
    final network = transaction['network']?.toString();
    final phoneNumber = transaction['phone_number']?.toString();
    final planName = transaction['plan_name']?.toString();
    final data = transaction['data']?.toString();
    final validity = transaction['validity']?.toString();
    final gateway = transaction['gateway']?.toString();

    final isData = (type?.toString() ?? '').toLowerCase() == 'data';
    final isWalletFund =
        (type?.toString() ?? '').toLowerCase() == 'wallet_fund';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + Amount
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _typeColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 34),
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.formatNaira(amount),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _statusColor(status),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _typeTitle(type),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor(status).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
                if (isReversed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay_rounded,
                            size: 11, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'AUTO-REFUNDED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Auto-refund info banner
            if (isReversed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${CurrencyFormatter.formatNaira(amount)} was automatically refunded to your wallet.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Source → Destination
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _endpointRow(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.primary,
                    label: 'Source',
                    value: isWalletFund
                        ? (gateway?.isNotEmpty == true
                            ? gateway!
                            : 'Payment Gateway')
                        : 'Your Wallet',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        Container(width: 1, height: 20, color: AppColors.divider),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_downward_rounded,
                            size: 14, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                  _endpointRow(
                    icon: isWalletFund
                        ? Icons.account_balance_wallet_outlined
                        : (isData ? Icons.wifi_rounded : Icons.call_rounded),
                    iconColor: _typeColor(type),
                    label: 'Destination',
                    value: isWalletFund
                        ? 'Your Wallet'
                        : (network?.isNotEmpty == true
                            ? '$network${phoneNumber?.isNotEmpty == true ? ' • $phoneNumber' : ''}'
                            : phoneNumber ?? 'N/A'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details
            _detailRow('Reference', reference),
            if (createdAt != null)
              Builder(builder: (_) {
                try {
                  return _detailRow(
                    'Date & Time',
                    DateFormatter.formatDateTime(DateTime.parse(createdAt)),
                  );
                } catch (_) {
                  return _detailRow('Date', createdAt);
                }
              }),
            if (network != null && network.isNotEmpty)
              _detailRow('Network', network),
            if (phoneNumber != null && phoneNumber.isNotEmpty)
              _detailRow('Phone Number', phoneNumber),
            if (isData && planName != null && planName.isNotEmpty)
              _detailRow('Plan', planName),
            if (isData && data != null && data.isNotEmpty)
              _detailRow('Data Volume', data),
            if (isData && validity != null && validity.isNotEmpty)
              _detailRow('Validity', validity),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _endpointRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}
