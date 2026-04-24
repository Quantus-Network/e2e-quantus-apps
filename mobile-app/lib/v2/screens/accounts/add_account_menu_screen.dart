import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/accounts/add_hardware_account_screen.dart';
import 'package:resonance_network_wallet/v2/screens/import/import_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AddAccountMenuScreen extends ConsumerStatefulWidget {
  const AddAccountMenuScreen({super.key});

  @override
  ConsumerState<AddAccountMenuScreen> createState() => _AddAccountMenuScreenState();
}

class _AddAccountMenuScreenState extends ConsumerState<AddAccountMenuScreen> {
  final AccountsService _accountsService = AccountsService();
  final HumanReadableChecksumService _checksumService = HumanReadableChecksumService();

  bool _isCreatingAccount = false;

  bool _isHardwareWallet(List<Account> accounts) {
    return accounts.isNotEmpty && accounts.every((a) => a.accountType == AccountType.keystone);
  }

  int _walletIndexForActiveAccount(List<Account> accounts, DisplayAccount? activeDisplayAccount) {
    if (activeDisplayAccount is RegularAccount) {
      return activeDisplayAccount.account.walletIndex;
    }
    if (activeDisplayAccount is EntrustedDisplayAccount) {
      final parent = accounts.firstWhereOrNull((a) => a.accountId == activeDisplayAccount.account.parentAccountId);
      if (parent != null) return parent.walletIndex;
    }
    return accounts.isNotEmpty ? accounts.first.walletIndex : 0;
  }

  Future<void> _onCreateNewAccount() async {
    if (_isCreatingAccount) return;

    setState(() => _isCreatingAccount = true);
    try {
      final accounts = ref.read(accountsProvider).value ?? <Account>[];
      final activeDisplayAccount = ref.read(activeAccountProvider).value;
      final walletIndex = _walletIndexForActiveAccount(accounts, activeDisplayAccount);
      final selectedWalletAccounts = accounts.where((a) => a.walletIndex == walletIndex).toList();

      if (_isHardwareWallet(selectedWalletAccounts)) {
        final created = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(builder: (context) => AddHardwareAccountScreen(walletIndex: walletIndex)),
        );
        if (created == true) {
          ref.invalidate(accountsProvider);
          ref.invalidate(activeAccountProvider);
          if (mounted) Navigator.of(context).pop();
        }
      } else {
        final draft = await _accountsService.createNewAccount(walletIndex: walletIndex);
        await _checksumService.getHumanReadableName(draft.accountId);
      }
    } catch (_) {
      if (mounted) {
        context.showErrorToaster(message: 'Could not add account.');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingAccount = false);
      }
    }
  }

  Future<void> _onImportAccount() async {
    final accounts = ref.read(accountsProvider).value ?? <Account>[];
    final walletIndex = nextNonHardwareWalletIndex(accounts);

    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => ImportWalletScreenV2(walletIndex: walletIndex)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Add Account'),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AddMenuRow(
            icon: Icons.add,
            title: 'Create New Account',
            subtitle: 'Generate a fresh wallet address',
            onTap: _onCreateNewAccount,
            colors: colors,
            text: context.themeText,
          ),
          const SizedBox(height: 16),
          Divider(color: colors.toasterBackground, height: 1),
          const SizedBox(height: 24),
          _AddMenuRow(
            icon: Icons.save_alt,
            title: 'Import Account',
            subtitle: 'Use a recovery phrase to import',
            onTap: _onImportAccount,
            colors: colors,
            text: context.themeText,
          ),
        ],
      ),
    );
  }
}

class _AddMenuRow extends StatelessWidget {
  const _AddMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final AppColorsV2 colors;
  final AppTextTheme text;

  @override
  Widget build(BuildContext context) {
    final containerSize = 40.0;
    final iconSize = 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: containerSize,
              height: containerSize,
              child: Center(
                child: Icon(icon, size: iconSize, color: colors.accentOrange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.paragraph?.copyWith(fontSize: 18)),
                  Text(subtitle, style: text.smallParagraph?.copyWith(color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
