import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/mnemonic_grid.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/remote_config_provider.dart';
import 'package:resonance_network_wallet/services/firebase_messaging_service.dart';
import 'package:resonance_network_wallet/services/wallet_creation_service.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/loader.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/accounts/account_ready_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class NewWalletRecoveryPhraseScreen extends ConsumerStatefulWidget {
  const NewWalletRecoveryPhraseScreen({super.key});

  @override
  ConsumerState<NewWalletRecoveryPhraseScreen> createState() => _NewWalletRecoveryPhraseScreenState();
}

class _NewWalletRecoveryPhraseScreenState extends ConsumerState<NewWalletRecoveryPhraseScreen> {
  final WalletCreationService _walletCreationService = WalletCreationService();
  final HdWalletService _hdWalletService = HdWalletService();

  final String _accountName = 'Account 1';
  final int _walletIndex = 0;
  List<String> _words = [];
  String _mnemonic = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _errorOccurred = false;

  late String _address;
  late String _checksum;

  Future<void> _generateMnemonic() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _mnemonic = await SubstrateService().generateMnemonic();
      if (_mnemonic.isEmpty) throw Exception('Mnemonic generation returned empty.');

      _words = _mnemonic.split(' ');
      _address = _hdWalletService.keyPairAtIndex(_mnemonic, 0).ss58Address;
      _checksum = await HumanReadableChecksumService().getHumanReadableName(_address);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorOccurred = true;
        });

        context.showErrorToaster(message: 'Failed to generate: $e');
      }
    }
  }

  Future<void> _continue() async {
    if (_words.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final accounts = ref.read(accountsProvider).value ?? <Account>[];
      await _walletCreationService.createNewWallet(
        name: _accountName,
        mnemonic: _mnemonic,
        walletIndex: _walletIndex,
        accountId: _address,
        existingAccounts: accounts,
      );

      ref.invalidate(accountsProvider);
      ref.invalidate(activeAccountProvider);

      if (ref.read(remoteConfigProvider).enableRemoteNotifications) {
        ref.read(firebaseMessagingServiceProvider).registerDeviceIfPossible();
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AccountReadyScreen(
            accountId: _address,
            accountName: _accountName,
            checksumPhrase: _checksum,
            origin: AccountReadyOverviewOrigin.walletCreated,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) context.showErrorToaster(message: 'Error saving wallet: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _copyToClipboard() {
    context.copyTextWithToaster(_words.join(' '), message: 'Recovery phrase copied to clipboard');
  }

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Create Wallet'),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Write these words down in order and keep them somewhere only you can access. Do not screenshot or copy to a notes app.',
            style: text.smallParagraph?.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: Loader(size: 24))
                : SingleChildScrollView(child: MnemonicGrid(words: _words, isRevealed: true)),
          ),
        ],
      ),
      bottomContent: _bottomBar(colors),
    );
  }

  Widget _bottomBar(AppColorsV2 colors) {
    return ScaffoldBaseBottomContent(
      child: Row(
        children: [
          Expanded(
            child: QuantusButton.simple(
              label: 'Copy',
              icon: Icon(Icons.copy, color: colors.textPrimary, size: 14),
              iconPlacement: IconPlacement.leading,
              onTap: _copyToClipboard,
              variant: ButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: QuantusButton.simple(
              label: 'Next',
              isDisabled: _errorOccurred,
              isLoading: _isLoading || _isSubmitting,
              onTap: _continue,
              variant: ButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }
}
