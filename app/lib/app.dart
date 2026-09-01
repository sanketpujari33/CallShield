import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/signal_ledger_theme.dart';
import 'presentation/screens/main_navigation_shell.dart';
import 'presentation/screens/onboarding/onboarding_wizard_screen.dart';
import 'presentation/state/activity_provider.dart';
import 'presentation/state/lookup_provider.dart';
import 'presentation/state/protection_provider.dart';
import 'presentation/state/rules_provider.dart';
import 'presentation/state/settings_provider.dart';
import 'presentation/state/stats_provider.dart';
import 'presentation/state/scanner_provider.dart';
import 'presentation/state/permissions_provider.dart';

class CallShieldApp extends StatelessWidget {
  const CallShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProtectionProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => RulesProvider()),
        ChangeNotifierProvider(create: (_) => LookupProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
        ChangeNotifierProvider(create: (_) => PermissionsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'CallShield',
            debugShowCheckedModeBanner: false,
            theme: SignalLedgerTheme.getTheme(settings.themeMode, context),
            home: settings.isLoaded
                ? (settings.hasCompletedOnboarding
                    ? const MainNavigationShell()
                    : const OnboardingWizardScreen())
                : const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        },
      ),
    );
  }
}
