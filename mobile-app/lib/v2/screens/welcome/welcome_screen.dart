import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/l10n_provider.dart';
import 'package:resonance_network_wallet/providers/remote_config_provider.dart';
import 'package:resonance_network_wallet/services/firebase_messaging_service.dart';
import 'package:resonance_network_wallet/services/wallet_creation_service.dart';
import 'package:resonance_network_wallet/shared/constants/e2e_keys.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/screens/accounts/account_ready_screen.dart';
import 'package:resonance_network_wallet/v2/screens/import/import_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/screens/welcome/onboarding_background.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class WelcomeScreenV2 extends ConsumerStatefulWidget {
  const WelcomeScreenV2({super.key});

  @override
  ConsumerState<WelcomeScreenV2> createState() => _WelcomeScreenV2State();
}

class _WelcomeScreenV2State extends ConsumerState<WelcomeScreenV2> {
  final WalletCreationService _walletCreationService = WalletCreationService();

  static const _accountName = 'Account 1';
  static const _walletIndex = 0;

  bool _isCreating = false;

  Future<void> _createWallet() async {
    setState(() => _isCreating = true);
    try {
      final mnemonic = await SubstrateService().generateMnemonic();
      if (mnemonic.isEmpty) throw Exception('Mnemonic generation returned empty.');

      final address = HdWalletService().keyPairAtIndex(mnemonic, 0).ss58Address;

      final accounts = ref.read(accountsProvider).value ?? <Account>[];
      await _walletCreationService.createNewWallet(
        name: _accountName,
        mnemonic: mnemonic,
        walletIndex: _walletIndex,
        accountId: address,
        existingAccounts: accounts,
      );

      ref.invalidate(accountsProvider);
      ref.invalidate(activeAccountProvider);

      unawaited(_registerForRemoteNotifications());

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AccountReadyScreen(
            accountId: address,
            accountName: _accountName,
            origin: AccountReadyOverviewOrigin.walletCreated,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        final l10n = ref.read(l10nProvider);
        context.showErrorToaster(message: l10n.createWalletRecoveryPhraseSaveError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  /// Best-effort push-notification registration.
  ///
  /// This must never block or abort wallet creation. `FirebaseMessaging.instance`
  /// throws when Firebase has not been initialized yet (it is initialized lazily
  /// once remote notifications are enabled), so tapping immediately after launch
  /// could otherwise throw here and skip navigation to the account-ready screen.
  Future<void> _registerForRemoteNotifications() async {
    try {
      if (!ref.read(remoteConfigProvider).enableRemoteNotifications) return;
      await ref.read(firebaseMessagingServiceProvider).registerDeviceIfPossible();
    } catch (_) {
      // Notifications are non-critical to wallet creation; ignore failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);

    return ScaffoldBase(
      key: const Key(E2EKeys.welcomeScreen),
      backgroundWidget: const OnboardingBackground(),
      mainContent: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset('assets/v2/quantus_orange_logo.png', height: 32),
          const SizedBox(height: 16),
          SizedBox(
            width: 210,
            child: Text(l10n.welcomeTagline, textAlign: TextAlign.center, style: context.themeText.mediumTitle),
          ),
          const SizedBox(height: 56),
          QuantusButton.simple(
            key: const Key(E2EKeys.welcomeCreateWalletButton),
            label: l10n.welcomeCreateNewWallet,
            onTap: _createWallet,
            isLoading: _isCreating,
          ),
          const SizedBox(height: 24),
          QuantusButton.simple(
            key: const Key(E2EKeys.welcomeImportWalletButton),
            label: l10n.welcomeImportWallet,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'import_wallet'),
                builder: (_) => const ImportWalletScreenV2(),
              ),
            ),
            variant: ButtonVariant.secondary,
            isDisabled: _isCreating,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
