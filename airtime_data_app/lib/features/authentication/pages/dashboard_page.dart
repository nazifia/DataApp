// Dashboard Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../event/auth_event.dart' hide LoadWalletEvent, FundWalletEvent;
import '../state/auth_state.dart'
    hide WalletLoading, WalletSuccess, WalletFailure;
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/event/wallet_event.dart';
import '../../wallet/state/wallet_state.dart';
import '../../airtime/bloc/airtime_bloc.dart';
import '../../airtime/state/airtime_state.dart';
import '../../data/bloc/data_bloc.dart';
import '../../data/state/data_state.dart';
import '../../transaction_history/bloc/transaction_history_bloc.dart';
import '../../transaction_history/event/transaction_history_event.dart';
import '../../transaction_history/state/transaction_history_state.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/validation.dart';
import '../../../main.dart' show routeObserver, themeModeNotifier;
import '../../../core/services/biometric_service.dart';
import '../../../core/services/theme_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  bool _balanceVisible = true;
  bool _biometricEnabled = false;
  bool _biometricCapable = false;

  void _refreshData() {
    context.read<WalletBloc>().add(const LoadWalletEvent());
    context.read<TransactionHistoryBloc>().add(LoadTransactionHistoryEvent());
    context.read<AuthBloc>().add(LoadProfileEvent());
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
    _loadBiometricStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when another route is popped back to this dashboard
  @override
  void didPopNext() {
    _refreshData();
  }

  Future<void> _loadBiometricStatus() async {
    final capable = await BiometricService.isDeviceCapable();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricCapable = capable;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final success = await BiometricService.enable();
      if (!mounted) return;
      if (success) {
        setState(() => _biometricEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login enabled'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification failed or not available'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await BiometricService.disable();
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login disabled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('TopUpNaija'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
        leading: const SizedBox(),
      ),
      endDrawer: _buildDrawer(context),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AirtimeBloc, AirtimeState>(
            listener: (context, state) {
              if (state is AirtimeSuccess) {
                context.read<WalletBloc>().add(const LoadWalletEvent());
                context
                    .read<TransactionHistoryBloc>()
                    .add(LoadTransactionHistoryEvent());
              }
            },
          ),
          BlocListener<DataBloc, DataState>(
            listener: (context, state) {
              if (state is DataSuccess) {
                context.read<WalletBloc>().add(const LoadWalletEvent());
                context
                    .read<TransactionHistoryBloc>()
                    .add(LoadTransactionHistoryEvent());
              }
            },
          ),
          BlocListener<WalletBloc, WalletState>(
            listener: (context, state) {
              if (state is WalletSuccess) {
                context
                    .read<TransactionHistoryBloc>()
                    .add(LoadTransactionHistoryEvent());
              }
            },
            // Only react to wallet success triggered by funding (not initial load)
            listenWhen: (previous, current) =>
                previous is WalletLoading && current is WalletSuccess,
          ),
        ],
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context.read<WalletBloc>().add(LoadWalletEvent());
            context
                .read<TransactionHistoryBloc>()
                .add(LoadTransactionHistoryEvent());
            context.read<AuthBloc>().add(LoadProfileEvent());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with wallet card
                _buildHeader(),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              Icons.call_rounded,
                              'Buy Airtime',
                              AppColors.primary,
                              const Color(0xFFE8F5E9),
                              () => Navigator.of(context)
                                  .pushNamed('/airtime-purchase'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              Icons.wifi_rounded,
                              'Buy Data',
                              AppColors.info,
                              const Color(0xFFE3F2FD),
                              () => Navigator.of(context)
                                  .pushNamed('/data-purchase'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              Icons.account_balance_wallet_rounded,
                              'Fund Wallet',
                              AppColors.warning,
                              const Color(0xFFFFF8E1),
                              () => Navigator.of(context)
                                  .pushNamed('/wallet-fund'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Recent Transactions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/transaction-history'),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row with profile avatar
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String name = 'User';
              String? profilePicture;

              if (state is AuthSuccess) {
                name = state.fullName.split(' ').first;
                profilePicture = state.profilePicture;
              } else if (state is ProfileSuccess) {
                name = (state.profileData['full_name']?.toString() ?? 'User')
                    .split(' ')
                    .first;
                profilePicture =
                    state.profileData['profile_picture']?.toString();
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $name 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'What would you like to do today?',
                          style: TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Tappable profile avatar → navigate to profile
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/profile'),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        backgroundImage: profilePicture != null
                            ? NetworkImage(profilePicture)
                            : null,
                        child: profilePicture == null
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Wallet balance card
          _buildWalletCard(),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        double balance = 0;
        bool isLoading = false;
        bool isError = false;

        if (state is WalletLoading) {
          isLoading = true;
        } else if (state is WalletSuccess) {
          balance = state.balance;
        } else if (state is WalletFailure) {
          isError = true;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _balanceVisible = !_balanceVisible),
                    child: Icon(
                      _balanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isLoading)
                Container(
                  width: 160,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else if (isError)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unable to load balance',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<WalletBloc>().add(LoadWalletEvent()),
                      child: const Text(
                        'Tap to retry',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  _balanceVisible
                      ? CurrencyFormatter.formatNaira(balance)
                      : '₦ ••••••',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/wallet-fund'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Money'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    IconData icon,
    String label,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return BlocBuilder<TransactionHistoryBloc, TransactionHistoryState>(
      builder: (context, state) {
        if (state is TransactionHistoryLoading) {
          return _buildShimmerTransactions();
        } else if (state is TransactionHistorySuccess) {
          if (state.transactions.isEmpty) {
            return _buildEmptyTransactions();
          }
          final items = state.transactions.take(5).toList();
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildTransactionItem(items[index]),
          );
        } else if (state is TransactionHistoryFailure) {
          return _buildErrorTransactions(state.message);
        } else {
          return _buildShimmerTransactions();
        }
      },
    );
  }

  Widget _buildShimmerTransactions() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    const SizedBox(height: 6),
                    Container(
                        width: 80, height: 11, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 70, height: 14, color: Theme.of(context).colorScheme.surfaceContainerHighest),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buy airtime or data to see history',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTransactions(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.red[400]),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return InkWell(
      onTap: () => _showTransactionDetails(context, transaction),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    _txColor(transaction['type']).withValues(alpha: 0.12),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (transaction['phone_number'] ??
                            transaction['reference'] ??
                            'N/A')
                        .toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                const SizedBox(height: 3),
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
                      fontWeight: FontWeight.w600,
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                String name = 'User';
                String phone = '';
                String? profilePicture;
                if (state is AuthSuccess) {
                  name = state.fullName;
                  phone = state.phoneNumber;
                  profilePicture = state.profilePicture;
                } else if (state is ProfileSuccess) {
                  name =
                      state.profileData['full_name']?.toString() ?? 'User';
                  phone =
                      state.profileData['phone_number']?.toString() ?? '';
                  profilePicture =
                      state.profileData['profile_picture']?.toString();
                }
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                      backgroundImage: profilePicture != null
                          ? NetworkImage(profilePicture)
                          : null,
                      child: profilePicture == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _drawerItem(Icons.home_rounded, 'Home', () {
                  Navigator.of(context).pop();
                }),
                _drawerItem(Icons.person_outline_rounded, 'My Profile', () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/profile');
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'SERVICES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _drawerItem(Icons.call_rounded, 'Buy Airtime', () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/airtime-purchase');
                }, color: AppColors.primary),
                _drawerItem(Icons.wifi_rounded, 'Buy Data', () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/data-purchase');
                }, color: AppColors.info),
                _drawerItem(
                    Icons.account_balance_wallet_rounded, 'Fund Wallet', () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/wallet-fund');
                }, color: AppColors.warning),
                _drawerItem(Icons.history_rounded, 'Transaction History',
                    () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/transaction-history');
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                _drawerItem(
                    Icons.help_outline_rounded, 'Help & Support', () {
                  Navigator.of(context).pop();
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Dark Mode toggle
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, _) {
                    final isDark = mode == ThemeMode.dark;
                    return SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.indigo,
                        size: 22,
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      value: isDark,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primary
                            : null,
                      ),
                      onChanged: (value) async {
                        final newMode =
                            value ? ThemeMode.dark : ThemeMode.light;
                        themeModeNotifier.value = newMode;
                        await ThemeService.saveThemeMode(newMode);
                      },
                    );
                  },
                ),
                // Biometric toggle
                if (_biometricCapable)
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    secondary: const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.teal,
                      size: 22,
                    ),
                    title: const Text(
                      'Biometric Login',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    value: _biometricEnabled,
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.primary
                          : null,
                    ),
                    onChanged: (value) {
                      Navigator.of(context).pop();
                      _toggleBiometric(value);
                    },
                  ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _drawerItem(
                  Icons.logout_rounded,
                  'Sign Out',
                  () {
                    context.read<AuthBloc>().add(const LogoutEvent());
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/welcome',
                      (route) => false,
                    );
                  },
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading:
          Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(Icons.home_rounded, 'Home', true, () {}),
              _bottomNavItem(Icons.call_rounded, 'Airtime', false,
                  () => Navigator.of(context).pushNamed('/airtime-purchase')),
              _bottomNavItem(Icons.wifi_rounded, 'Data', false,
                  () => Navigator.of(context).pushNamed('/data-purchase')),
              _bottomNavItem(Icons.history_rounded, 'History', false,
                  () => Navigator.of(context)
                      .pushNamed('/transaction-history')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
      IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _txColor(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime':
        return AppColors.primary;
      case 'data':
        return AppColors.info;
      case 'wallet_fund':
        return AppColors.warning;
      case 'refund':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _txIcon(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime':
        return Icons.call_rounded;
      case 'data':
        return Icons.wifi_rounded;
      case 'wallet_fund':
        return Icons.account_balance_wallet_rounded;
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _txTitle(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime':
        return 'Airtime Purchase';
      case 'data':
        return 'Data Purchase';
      case 'wallet_fund':
        return 'Wallet Funding';
      case 'refund':
        return 'Refund';
      default:
        return 'Transaction';
    }
  }

  Color _statusColor(dynamic status) {
    switch ((status?.toString() ?? '').toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ─── Transaction Detail Sheet ──────────────────────────────────────────────

class _TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionDetailSheet({required this.transaction});

  Color _typeColor(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime':
        return AppColors.primary;
      case 'data':
        return AppColors.info;
      case 'wallet_fund':
        return AppColors.warning;
      case 'refund':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime':
        return Icons.call_rounded;
      case 'data':
        return Icons.wifi_rounded;
      case 'wallet_fund':
        return Icons.account_balance_wallet_rounded;
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _typeTitle(dynamic type) {
    switch ((type?.toString() ?? '').toLowerCase()) {
      case 'airtime':
        return 'Airtime Purchase';
      case 'data':
        return 'Data Purchase';
      case 'wallet_fund':
        return 'Wallet Funding';
      case 'refund':
        return 'Refund';
      default:
        return 'Transaction';
    }
  }

  Color _statusColor(dynamic status) {
    switch ((status?.toString() ?? '').toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'];
    final status = transaction['status'];
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _typeColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _typeIcon(type),
                color: _typeColor(type),
                size: 34,
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            Text(
              CurrencyFormatter.formatNaira(amount),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _statusColor(status),
              ),
            ),
            const SizedBox(height: 8),

            // Type label
            Text(
              _typeTitle(type),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (status?.toString() ?? 'unknown').toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(status),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            _detailRow(context, 'Reference', reference),
            if (network != null) _detailRow(context, 'Network', network),
            if (phoneNumber != null) _detailRow(context, 'Phone', phoneNumber),
            if (isData && planName != null)
              _detailRow(context, 'Plan', planName),
            if (isData && data != null) _detailRow(context, 'Volume', data),
            if (isData && validity != null)
              _detailRow(context, 'Validity', validity),
            if (isWalletFund && gateway != null)
              _detailRow(context, 'Gateway', gateway),
            if (createdAt != null) _detailRow(context, 'Date', createdAt),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
