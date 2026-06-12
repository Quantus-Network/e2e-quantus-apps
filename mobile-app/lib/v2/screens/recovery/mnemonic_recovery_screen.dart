import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/l10n_provider.dart';
import 'package:resonance_network_wallet/providers/remote_config_provider.dart';
import 'package:resonance_network_wallet/services/firebase_messaging_service.dart';
import 'package:resonance_network_wallet/services/logout_service.dart';
import 'package:resonance_network_wallet/services/telemetry_service.dart';
import 'package:resonance_network_wallet/shared/utils/print.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/home/home_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

/// Screen shown when the app detects that accounts exist but the mnemonic is
/// missing from secure storage. This can happen after iOS/Android updates when
/// the secure storage plugin fails to read/migrate keychain data.
///
/// CRITICAL: This screen does NOT call logout or clearAll. It preserves the
/// user's account metadata (in SharedPreferences) so they can re-import their
/// seed phrase and recover their wallet.
class MnemonicRecoveryScreen extends ConsumerStatefulWidget {
  const MnemonicRecoveryScreen({super.key});

  @override
  ConsumerState<MnemonicRecoveryScreen> createState() => _MnemonicRecoveryScreenState();
}

class _MnemonicRecoveryScreenState extends ConsumerState<MnemonicRecoveryScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _buttonKey = GlobalKey();
  final _settingsService = SettingsService();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_revealButton);
  }

  void _revealButton() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 400), () {
        final ctx = _buttonKey.currentContext;
        if (mounted && ctx != null) {
          // ignore: use_build_context_synchronously
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });
    }
  }

  bool get _hasInput => _controller.text.trim().isNotEmpty;

  Future<void> _recoverWallet() async {
    final l10n = ref.read(l10nProvider);
    final mnemonic = _controller.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Validate mnemonic format (unless it's a dev account path like //Alice)
      if (!mnemonic.startsWith('//')) {
        final words = mnemonic.split(' ').where((w) => w.isNotEmpty).toList();
        if (words.length != 12 && words.length != 24) {
          throw Exception(l10n.importWalletValidationError);
        }
      }

      // Verify the mnemonic produces the expected account
      final existingAccounts = await _settingsService.getAccounts();
      if (existingAccounts.isEmpty) {
        throw Exception('No accounts found to recover');
      }

      // Check if the mnemonic derives the same root account
      final key = HdWalletService().keyPairAtIndex(mnemonic, 0);
      final rootAccount = existingAccounts.firstWhere(
        (a) => a.walletIndex == 0 && a.index == 0,
        orElse: () => existingAccounts.first,
      );

      if (key.ss58Address != rootAccount.accountId) {
        throw Exception(
          'This recovery phrase does not match your wallet. '
          'Expected address starting with ${rootAccount.accountId.substring(0, 8)}..., '
          'but got ${key.ss58Address.substring(0, 8)}...',
        );
      }

      // Mnemonic is valid and matches - restore it to secure storage
      await _settingsService.setMnemonic(mnemonic, 0);
      TelemetryService().sendEvent('mnemonic_recovered_successfully');
      quantusDebugPrint('MNEMONIC RECOVERED: user successfully re-imported matching seed phrase');

      // Re-register for notifications if enabled
      if (ref.read(remoteConfigProvider).enableRemoteNotifications) {
        ref.read(firebaseMessagingServiceProvider).registerDeviceIfPossible();
      }

      // Reload accounts and navigate to home
      ref.invalidate(accountsProvider);
      ref.invalidate(activeAccountProvider);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
    } catch (e) {
      TelemetryService().sendEvent('mnemonic_recovery_failed', parameters: {'error': e.toString()});
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startFresh() async {
    // User wants to completely reset - this IS destructive and intentional
    if (!mounted) return;
    ref.read(logoutServiceProvider).logout(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final colors = context.colors;
    final text = context.themeText;
    final fieldTextStyle = text.smallTitle?.copyWith(color: colors.checksum, fontWeight: FontWeight.w400);

    return ScaffoldBase(
      appBar: V2AppBar(title: l10n.walletInitErrorTitle),
      mainContent: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning icon and explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.accentOrange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colors.accentOrange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.walletInitErrorMessage,
                        style: text.smallParagraph?.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Explanation text
              Text(
                'Your account data is still safe. Enter your 12 or 24 word recovery phrase below to restore access to your wallet.',
                style: text.smallParagraph?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Recovery phrase input
              Container(
                height: 202,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceDeep,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderButton, width: 1),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (_) => setState(() {}),
                  style: fieldTextStyle,
                  decoration: InputDecoration.collapsed(
                    hintText: l10n.importWalletHint,
                    hintStyle: fieldTextStyle?.copyWith(color: colors.textSecondary),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                ),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: text.detail?.copyWith(color: colors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Start fresh option (destructive)
              Center(
                child: TextButton(
                  onPressed: _startFresh,
                  child: Text(
                    'Or start fresh with a new wallet',
                    style: text.detail?.copyWith(
                      color: colors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomContent: ScaffoldBaseBottomContent(
        child: QuantusButton.simple(
          key: _buttonKey,
          label: 'Restore Wallet',
          onTap: _recoverWallet,
          isLoading: _isLoading,
          isDisabled: !_hasInput,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_revealButton);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}
