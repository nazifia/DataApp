// Main Application File
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_env.dart';
import 'core/network/api_client.dart';
import 'core/services/theme_service.dart';
import 'core/services/notification_service.dart';
import 'features/authentication/bloc/auth_bloc.dart';
import 'features/authentication/data/auth_repository.dart';
import 'features/wallet/bloc/wallet_bloc.dart';
import 'features/wallet/data/wallet_repository.dart';
import 'features/airtime/bloc/airtime_bloc.dart';
import 'features/airtime/data/airtime_repository.dart';
import 'features/data/bloc/data_bloc.dart';
import 'features/data/data_repository.dart';
import 'features/transaction_history/bloc/transaction_history_bloc.dart';
import 'features/transaction_history/data/transaction_history_repository.dart';
import 'features/beneficiaries/bloc/beneficiary_bloc.dart';
import 'features/beneficiaries/data/beneficiary_repository.dart';
import 'features/bills/bloc/bills_bloc.dart';
import 'features/bills/data/bills_repository.dart';
import 'features/referrals/bloc/referrals_bloc.dart';
import 'features/referrals/data/referrals_repository.dart';
import 'features/disputes/bloc/disputes_bloc.dart';
import 'features/disputes/data/disputes_repository.dart';
import 'features/agents/bloc/agents_bloc.dart';
import 'features/agents/data/agents_repository.dart';
import 'features/notifications/bloc/notifications_bloc.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/admin/bloc/admin_bloc.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/authentication/pages/splash_page.dart';
import 'features/authentication/pages/welcome_page.dart';
import 'features/authentication/pages/phone_input_page.dart';
import 'features/authentication/pages/business_registration_page.dart';
import 'features/authentication/pages/otp_verification_page.dart';
import 'features/authentication/pages/profile_setup_page.dart';
import 'features/authentication/pages/dashboard_page.dart';
import 'features/airtime/pages/airtime_purchase_page.dart';
import 'features/data/pages/data_purchase_page.dart';
import 'features/bills/pages/electricity_purchase_page.dart';
import 'features/bills/pages/tv_purchase_page.dart';
import 'features/referrals/pages/referrals_page.dart';
import 'features/disputes/pages/disputes_page.dart';
import 'features/agents/pages/agent_page.dart';
import 'features/notifications/pages/notifications_page.dart';
import 'features/admin/pages/admin_earnings_page.dart';
import 'features/admin/pages/business_settings_page.dart';
import 'features/wallet/pages/wallet_fund_page.dart';
import 'features/transaction_history/pages/transaction_history_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/theme.dart';
import 'core/widgets/inactivity_detector.dart';

// Active environment — switch in AppConfig.active (app_env.dart)
final _config = AppConfig.active;

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// Global notifier for theme mode — updated from Profile page
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase web needs explicit FirebaseOptions (not configured). Skip on web —
  // push notifications are already disabled for web in NotificationService.
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  await NotificationService.initialize();
  themeModeNotifier.value = await ThemeService.loadThemeMode();
  runApp(AirtimeDataApp(config: _config));
}

class AirtimeDataApp extends StatelessWidget {
  final AppConfig config;

  const AirtimeDataApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(config);
    final authRepository =
        AuthRepository(apiClient: apiClient, config: config);
    final walletRepository =
        WalletRepository(apiClient: apiClient, config: config);
    final airtimeRepository =
        AirtimeRepository(apiClient: apiClient, config: config);
    final dataRepository =
        DataRepository(apiClient: apiClient, config: config);
    final transactionHistoryRepository =
        TransactionHistoryRepository(apiClient: apiClient, config: config);
    final beneficiaryRepository =
        BeneficiaryRepository(apiClient: apiClient, config: config);
    final billsRepository =
        BillsRepository(apiClient: apiClient, config: config);
    final referralsRepository =
        ReferralsRepository(apiClient: apiClient, config: config);
    final disputesRepository =
        DisputesRepository(apiClient: apiClient, config: config);
    final agentsRepository =
        AgentsRepository(apiClient: apiClient, config: config);
    final notificationsRepository =
        NotificationsRepository(apiClient: apiClient, config: config);
    final adminRepository =
        AdminRepository(apiClient: apiClient, config: config);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: transactionHistoryRepository),
        RepositoryProvider.value(value: beneficiaryRepository),
        RepositoryProvider.value(value: billsRepository),
        // Exposed for the agent sale page's product catalogs.
        RepositoryProvider.value(value: dataRepository),
        RepositoryProvider.value(value: referralsRepository),
        RepositoryProvider.value(value: disputesRepository),
        RepositoryProvider.value(value: agentsRepository),
        RepositoryProvider.value(value: notificationsRepository),
        RepositoryProvider.value(value: adminRepository),
        RepositoryProvider.value(value: walletRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepository),
          ),
          BlocProvider(
            create: (_) => WalletBloc(walletRepository: walletRepository),
          ),
          BlocProvider(
            create: (_) => AirtimeBloc(airtimeRepository: airtimeRepository),
          ),
          BlocProvider(
            create: (_) => DataBloc(dataRepository: dataRepository),
          ),
          BlocProvider(
            create: (_) => TransactionHistoryBloc(
                transactionHistoryRepository: transactionHistoryRepository),
          ),
          BlocProvider(
            create: (_) =>
                BeneficiaryBloc(repository: beneficiaryRepository),
          ),
          // App-level so the dashboard bell badge and the list page share state.
          BlocProvider(
            create: (_) => NotificationsBloc(
                repository: notificationsRepository),
          ),
        ],
        child: InactivityDetector(
          navigatorKey: _navigatorKey,
          child: ListenableBuilder(
            listenable: themeModeNotifier,
            builder: (context, _) {
              return MaterialApp(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeModeNotifier.value,
                navigatorKey: _navigatorKey,
                navigatorObservers: [routeObserver],
                initialRoute: '/',
                routes: {
                  '/': (context) => const SplashPage(),
                  '/welcome': (context) => const WelcomePage(),
                  '/phone-input': (context) => PhoneInputPage(
                        isLogin: (ModalRoute.of(context)!.settings.arguments
                                as bool?) ??
                            true,
                      ),
                  '/otp-verification': (context) {
                    final args = ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                    return OtpVerificationPage(
                      phoneNumber: args['phoneNumber'] as String,
                      isLogin: args['isLogin'] as bool,
                    );
                  },
                  '/profile-setup': (context) => ProfileSetupPage(
                      phoneNumber:
                          ModalRoute.of(context)!.settings.arguments as String),
                  '/register-business': (context) =>
                      const BusinessRegistrationPage(),
                  '/dashboard': (context) => const DashboardPage(),
                  '/airtime-purchase': (context) => const AirtimePurchasePage(),
                  '/data-purchase': (context) => const DataPurchasePage(),
                  '/electricity': (context) => BlocProvider(
                        create: (ctx) => BillsBloc(
                            repository: ctx.read<BillsRepository>()),
                        child: const ElectricityPurchasePage(),
                      ),
                  '/tv': (context) => BlocProvider(
                        create: (ctx) => BillsBloc(
                            repository: ctx.read<BillsRepository>()),
                        child: const TvPurchasePage(),
                      ),
                  '/wallet-fund': (context) => const WalletFundPage(),
                  '/transaction-history': (context) =>
                      const TransactionHistoryPage(),
                  '/profile': (context) => const ProfilePage(),
                  '/referrals': (context) => BlocProvider(
                        create: (ctx) => ReferralsBloc(
                            repository: ctx.read<ReferralsRepository>()),
                        child: const ReferralsPage(),
                      ),
                  '/disputes': (context) => BlocProvider(
                        create: (ctx) => DisputesBloc(
                            repository: ctx.read<DisputesRepository>()),
                        child: const DisputesPage(),
                      ),
                  '/agent': (context) => BlocProvider(
                        create: (ctx) => AgentsBloc(
                            repository: ctx.read<AgentsRepository>()),
                        child: const AgentPage(),
                      ),
                  // Uses the app-level NotificationsBloc (shared with the badge).
                  '/notifications': (context) => const NotificationsPage(),
                  // Business owner (admin) screens. Each gets a fresh AdminBloc so
                  // earnings and settings never share state. Non-admins see a
                  // friendly 403 view rendered inside the page.
                  '/admin/earnings': (context) => BlocProvider(
                        create: (ctx) => AdminBloc(
                            repository: ctx.read<AdminRepository>()),
                        child: const AdminEarningsPage(),
                      ),
                  '/admin/settings': (context) => BlocProvider(
                        create: (ctx) => AdminBloc(
                            repository: ctx.read<AdminRepository>()),
                        child: const BusinessSettingsPage(),
                      ),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
