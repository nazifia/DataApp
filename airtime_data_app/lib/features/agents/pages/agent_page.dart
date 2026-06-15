// Agent (POS) entry page — shows dashboard, or the apply screen for non-agents.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/agents_bloc.dart';
import '../event/agents_event.dart';
import '../state/agents_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';
import 'agent_sale_page.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final _businessController = TextEditingController();
  final _applyFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<AgentsBloc>().add(const LoadAgentDashboardEvent());
  }

  @override
  void dispose() {
    _businessController.dispose();
    super.dispose();
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
        title: const Text('POS Agent'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AgentsBloc, AgentsState>(
        listener: (context, state) {
          if (state is AgentApplyFailed) _snack(state.message, error: true);
          if (state is AgentApplied) {
            _snack('Application submitted — pending approval.');
          }
          if (state is AgentsError) _snack(state.message, error: true);
        },
        builder: (context, state) {
          if (state is AgentsLoading ||
              state is AgentsInitial ||
              state is AgentApplied) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AgentDashboardLoaded) return _dashboard(state);
          // NotRegistered / Applying / ApplyFailed / Error → apply screen.
          return _applyScreen(state is AgentApplying);
        },
      ),
    );
  }

  // ─── Dashboard ──────────────────────────────────────────────────────────
  Widget _dashboard(AgentDashboardLoaded s) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<AgentsBloc>().add(const LoadAgentDashboardEvent()),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _floatCard(s),
          if (!s.isActive) ...[
            const SizedBox(height: 16),
            _statusBanner(s.status),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.shopping_bag_rounded,
                  '${s.totalSalesCount}',
                  'Total Sales',
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  Icons.payments_rounded,
                  CurrencyFormatter.formatNaira(s.totalCommission),
                  'Commission Earned',
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statCard(
            Icons.bar_chart_rounded,
            CurrencyFormatter.formatNaira(s.totalSalesVolume),
            'Total Sales Volume',
            AppColors.primary,
            fullWidth: true,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'New Sale',
            onPressed: s.isActive ? () { _openSale(s); } : null,
          ),
          if (!s.isActive) ...[
            const SizedBox(height: 8),
            Text(
              'Sales are available once your agent account is active.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSale(AgentDashboardLoaded s) async {
    final bloc = context.read<AgentsBloc>();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AgentSalePage(floatBalance: s.floatBalance),
      ),
    ));
    // Refresh stats/float after returning from a sale.
    bloc.add(const LoadAgentDashboardEvent());
  }

  Widget _floatCard(AgentDashboardLoaded s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (s.agent['business_name'] ?? 'My Store').toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (s.agent['agent_code'] ?? '').toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('FLOAT BALANCE',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatNaira(s.floatBalance),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Commission rate: ${s.agent['commission_percent'] ?? 0}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    final pending = status == 'pending';
    final color = pending ? AppColors.warning : AppColors.error;
    final text = pending
        ? 'Your agent application is awaiting approval.'
        : 'Your agent account is suspended. Contact support.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(pending ? Icons.hourglass_top_rounded : Icons.block_rounded,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color,
      {bool fullWidth = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: fullWidth ? double.infinity : null,
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
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  // ─── Apply screen ───────────────────────────────────────────────────────
  Widget _applyScreen(bool submitting) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _applyFormKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 42, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Become a POS Agent',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Sell airtime, data, electricity and TV to your customers and earn commission on every sale.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 28),
          const Text('Business Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _businessController,
            decoration: const InputDecoration(
              hintText: 'e.g. Bola Telecom Hub',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'Enter your business name'
                : null,
          ),
          const SizedBox(height: 28),
          CustomButton(
            text: submitting ? 'Submitting...' : 'Apply Now',
            isLoading: submitting,
            onPressed: submitting
                ? null
                : () {
                    if (!(_applyFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    context
                        .read<AgentsBloc>()
                        .add(ApplyAgentEvent(_businessController.text.trim()));
                  },
          ),
        ],
      ),
    );
  }
}
