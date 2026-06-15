// Referrals Page — show referral code, invite count, earnings.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/referrals_bloc.dart';
import '../event/referrals_event.dart';
import '../state/referrals_state.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReferralsBloc>().add(const LoadReferralsEvent());
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<ReferralsBloc, ReferralsState>(
        builder: (context, state) {
          if (state is ReferralsLoading || state is ReferralsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReferralsError) {
            return _errorView(state.message);
          }
          final s = state as ReferralsLoaded;
          return RefreshIndicator(
            onRefresh: () async => context
                .read<ReferralsBloc>()
                .add(const LoadReferralsEvent()),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _heroCard(s),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        Icons.group_rounded,
                        '${s.invitedCount}',
                        'Friends Invited',
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        Icons.payments_rounded,
                        CurrencyFormatter.formatNaira(s.totalEarned),
                        'Total Earned',
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _howItWorks(s.bonusPerReferral),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heroCard(ReferralsLoaded s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite friends, earn rewards',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'You earn ${CurrencyFormatter.formatNaira(s.bonusPerReferral)} when a friend signs up with your code and makes their first purchase.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text('YOUR REFERRAL CODE',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    s.referralCode,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2),
                  ),
                ),
                _pillButton(Icons.copy_rounded, 'Copy', () {
                  Clipboard.setData(ClipboardData(text: s.referralCode));
                  _snack('Referral code copied');
                }),
                const SizedBox(width: 8),
                _pillButton(Icons.share_rounded, 'Share', () {
                  Clipboard.setData(ClipboardData(
                      text:
                          'Join me on TopUpNaija! Use my referral code ${s.referralCode} to sign up and we both earn rewards.'));
                  _snack('Invite message copied — paste it anywhere to share');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
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
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _howItWorks(double bonus) {
    final steps = [
      ('Share your code', 'Send your referral code to friends.'),
      ('They sign up', 'Your friend registers using your code.'),
      (
        'You both earn',
        'You get ${CurrencyFormatter.formatNaira(bonus)} after their first purchase.'
      ),
    ];
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
          const Text('How it works',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(steps[i].$2,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1) const SizedBox(height: 14),
          ],
        ],
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
              onPressed: () => context
                  .read<ReferralsBloc>()
                  .add(const LoadReferralsEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
