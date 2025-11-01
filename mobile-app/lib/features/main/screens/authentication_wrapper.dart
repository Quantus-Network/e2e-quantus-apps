import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/main/screens/wallet_initializer.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/services/local_auth_service.dart';

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> with WidgetsBindingObserver {
  final LocalAuthService _localAuthService = LocalAuthService();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  bool _hasProcessedArguments = false;
  TransactionEvent? _transaction;
  String? _address;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasProcessedArguments) {
      _hasProcessedArguments = true;
      _processArguments();
      _checkAuthentication();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthentication();
    }
  }

  Future<void> _checkAuthentication() async {
    // Prevent multiple auth checks at the same time
    if (_isAuthenticating) return;

    final shouldAuth = _localAuthService.shouldRequireAuthentication();

    if (shouldAuth) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
      _authenticate();
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    if (mounted) {
      setState(() {
        _isAuthenticating = true;
      });
    }

    final didAuthenticate = await _localAuthService.authenticate(
      localizedReason: 'Please authenticate to access your wallet',
    );

    if (mounted) {
      setState(() {
        _isAuthenticated = didAuthenticate;
        _isAuthenticating = false;
      });
    }
  }

  void _processArguments() {
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is TransactionEvent) {
      print('Argument is a TransactionEvent from notification.');

      setState(() {
        _transaction = arguments;
      });
    } else if (arguments is String) {
      print('Argument is a String address from a deep link.');

      setState(() {
        _address = arguments;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated ? WalletInitializer(address: _address, transaction: _transaction) : _buildLockScreen();
  }

  Widget _buildLockScreen() {
    return ScaffoldBase(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Authentication Required', style: context.themeText.lockTitle),
            const SizedBox(height: 30),
            if (_isAuthenticating)
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.themeColors.circularLoader))
            else
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themeColors.authButtonBg,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('Authenticate', style: context.themeText.paragraph),
              ),
          ],
        ),
      ),
    );
  }
}
