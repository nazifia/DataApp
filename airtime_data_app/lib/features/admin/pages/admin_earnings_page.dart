// Business Earnings Page — owner-only view of markup earnings (profit),
// revenue, and a per-product / daily breakdown over a selectable window.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../event/admin_event.dart';
import '../state/admin_state.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';

class AdminEarningsPage extends StatefulWidget {
  const AdminEarningsPage({super.key});

  @override
  State<AdminEarningsPage> createState() => _AdminEarningsPageState();
}

class _AdminEarningsPageState extends State<AdminEarningsPage> {
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      context.read<AdminBloc>().add(LoadEarningsEvent(days: _days));

  static const _typeLabels = {
    'airtime': 'Airtime',
    'data': 'Data',
    'electricity': 'Electricity',
    'tv': 'Cable TV',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Earnings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Business Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () =>
                Navigator.of(context).pushNamed('/admin/settings'),
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
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
          final s = state as EarningsLoaded;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _rangeSelector(),
                const SizedBox(height: 16),
                _profitHero(s),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        Icons.receipt_long_rounded,
                        CurrencyFormatter.formatNaira(s.totalRevenue),
                        'Revenue',
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        Icons.swap_horiz_rounded,
                        '${s.transactionCount}',
                        'Sales',
                        const Color(0xFF7C4DFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        Icons.account_balance_wallet_rounded,
                        CurrencyFormatter.formatNaira(s.walletBalance),
                        'Customer Wallets',
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        Icons.group_rounded,
                        '${s.activeUsers}/${s.totalUsers}',
                        'Active Users',
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _byTypeCard(s),
                const SizedBox(height: 16),
                _dailyCard(s),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rangeSelector() {
    final options = {7: '7D', 30: '30D', 90: '90D', 365: '1Y'};
    return SegmentedButton<int>(
      segments: [
        for (final e in options.entries)
          ButtonSegment(value: e.key, label: Text(e.value)),
      ],
      selected: {_days},
      showSelectedIcon: false,
      onSelectionChanged: (sel) {
        setState(() => _days = sel.first);
        _reload();
      },
    );
  }

  Widget _profitHero(EarningsLoaded s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFIT (LAST ${s.days} DAYS)',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatNaira(s.totalProfit),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.today_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Today: ${CurrencyFormatter.formatNaira(s.todayProfit)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your markup earnings on completed airtime, data and bill sales.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _byTypeCard(EarningsLoaded s) {
    final cs = Theme.of(context).colorScheme;
    final maxProfit = s.byType.fold<double>(
        0,
        (m, e) =>
            ((e['profit'] as num?)?.toDouble() ?? 0) > m
                ? (e['profit'] as num).toDouble()
                : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit by product',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (s.byType.isEmpty)
            Text('No sales in this period.',
                style:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.6)))
          else
            for (final row in s.byType) ...[
              _byTypeRow(row, maxProfit, cs),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _byTypeRow(
      Map<String, dynamic> row, double maxProfit, ColorScheme cs) {
    final type = row['type']?.toString() ?? '';
    final profit = (row['profit'] as num?)?.toDouble() ?? 0;
    final count = (row['count'] as num?)?.toInt() ?? 0;
    final frac = maxProfit > 0 ? (profit / maxProfit).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(_typeLabels[type] ?? type,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            Text(CurrencyFormatter.formatNaira(profit),
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 6,
            backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
        ),
        const SizedBox(height: 4),
        Text('$count sales',
            style: TextStyle(
                fontSize: 11.5,
                color: cs.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _dailyCard(EarningsLoaded s) {
    final cs = Theme.of(context).colorScheme;
    final rows = s.daily.reversed.take(14).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily breakdown',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('No sales in this period.',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(row['day']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Text('${(row['count'] as num?)?.toInt() ?? 0} sales',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(width: 16),
                    Text(
                      CurrencyFormatter.formatNaira(
                          (row['profit'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success),
                    ),
                  ],
                ),
              ),
        ],
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
            const Text(
              'Owner access only',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
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
              onPressed: _reload,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
