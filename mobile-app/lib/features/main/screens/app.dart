import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/main/screens/authentication_wrapper.dart';
import 'package:resonance_network_wallet/features/main/screens/send/send_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_theme.dart';

class ResonanceWalletApp extends StatelessWidget {
  const ResonanceWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quantus Wallet',
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthenticationWrapper(),
        '/send': (context) => const SendScreen(),
      },
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.dark,
    );
  }
}
