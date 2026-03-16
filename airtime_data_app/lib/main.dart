// Main Application File
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_env.dart';
import 'core/network/api_client.dart';
import 'core/services/theme_service.dart';
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
import 'features/authentication/pages/splash_page.dart';
import 'features/authentication/pages/welcome_page.dart';
import 'features/authentication/pages/phone_input_page.dart';
import 'features/authentication/pages/otp_verification_page.dart';
import 'features/authentication/pages/profile_setup_page.dart';
import 'features/authentication/pages/dashboard_page.dart';
import 'features/airtime/pages/airtime_purchase_page.dart';
import 'features/data/pages/data_purchase_page.dart';
import 'features/wallet/pages/wallet_fund_page.dart';
import 'features/transaction_history/pages/transaction_history_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/theme.dart';
import 'core/widgets/inactivity_detector.dart';

// Switch to AppConfig.prod before releasing to production
const _config = AppConfig.dev;

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// Global notifier for theme mode — updated from Profile page
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted theme before first frame
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

    return MultiBlocProvider(
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
                      isLogin:
                          ModalRoute.of(context)!.settings.arguments as bool,
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
                '/dashboard': (context) => const DashboardPage(),
                '/airtime-purchase': (context) => const AirtimePurchasePage(),
                '/data-purchase': (context) => const DataPurchasePage(),
                '/wallet-fund': (context) => const WalletFundPage(),
                '/transaction-history': (context) =>
                    const TransactionHistoryPage(),
                '/profile': (context) => const ProfilePage(),
              },
            );
          },
        ),
      ),
    );
  }
}
