import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/l10n_provider.dart';
import 'package:resonance_network_wallet/providers/multisig_providers.dart';
import 'package:resonance_network_wallet/providers/remote_config_provider.dart';
import 'package:resonance_network_wallet/shared/utils/account_utils.dart';
import 'package:resonance_network_wallet/v2/components/bottom_sheet_container.dart';
import 'package:resonance_network_wallet/v2/components/quantus_icon_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/accounts/add_hardware_account_screen.dart';
import 'package:resonance_network_wallet/v2/screens/accounts/create_account_screen.dart';
import 'package:resonance_network_wallet/v2/screens/import/import_wallet_screen.dart';
import 'package:resonance_network_wallet/v2/screens/multisig/add_multisig_screen.dart';
import 'package:resonance_network_wallet/v2/screens/multisig/discover_multisig_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AddAccountMenuScreen extends ConsumerStatefulWidget {
  const AddAccountMenuScreen({super.key});

  @override
  ConsumerState<AddAccountMenuScreen> createState() => _AddAccountMenuScreenState();
}

class _AddAccountMenuScreenState extends ConsumerState<AddAccountMenuScreen> {
  void _onCreateNewAccount() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAccountScreen()));
  }

  void _onImportWallet() {
    final accounts = ref.read(accountsProvider).value ?? <Account>[];
    final walletIndex = nextNonHardwareWalletIndex(accounts);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImportWalletScreenV2(walletIndex: walletIndex, openAccountsOnComplete: true)),
    );
  }

  void _onImportKeystone() {
    final accounts = ref.read(accountsProvider).value ?? <Account>[];
    final walletIndex = nextWalletIndex(accounts);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddHardwareAccountScreen(walletIndex: walletIndex, isNewWallet: true)));
  }

  void _onImportMultisig() {
    ref.invalidate(discoveredMultisigsProvider);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscoverMultisigScreen()));
  }

  void _onCreateMultisig() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddMultisigScreen()));
  }

  void _showMoreMenu() {
    final l10n = ref.read(l10nProvider);
    final enableMultisig = ref.read(remoteConfigProvider).enableMultisig;

    BottomSheetContainer.show<void>(
      context,
      builder: (sheetContext) => BottomSheetContainer(
        title: l10n.addAccountMenuMoreTitle,
        child: _MenuList(
          rows: [
            _AddMenuRow(
              icon: Icons.save_alt,
              title: l10n.addAccountMenuImportTitle,
              subtitle: l10n.addAccountMenuImportSubtitle,
              onTap: () {
                Navigator.pop(sheetContext);
                _onImportWallet();
              },
            ),
            if (enableMultisig) ...[
              _AddMenuRow(
                icon: Icons.radar_outlined,
                title: l10n.addAccountMenuDiscoverMultisigTitle,
                subtitle: l10n.addAccountMenuDiscoverMultisigSubtitle,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _onImportMultisig();
                },
              ),
              _AddMenuRow(
                icon: Icons.group_outlined,
                title: l10n.addAccountMenuMultisigTitle,
                subtitle: l10n.addAccountMenuMultisigSubtitle,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _onCreateMultisig();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);

    return ScaffoldBase(
      appBar: V2AppBar(
        title: l10n.addAccountMenuTitle,
        trailing: QuantusIconButton.circular(icon: Icons.more_horiz, onTap: _showMoreMenu),
      ),
      mainContent: _MenuList(
        rows: [
          _AddMenuRow(
            icon: Icons.add,
            title: l10n.addAccountMenuCreateTitle,
            subtitle: l10n.addAccountMenuCreateSubtitle,
            onTap: _onCreateNewAccount,
          ),
          _AddMenuRow(
            icon: Icons.qr_code_scanner,
            title: l10n.addAccountMenuImportKeystoneTitle,
            subtitle: l10n.addAccountMenuImportKeystoneSubtitle,
            onTap: _onImportKeystone,
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.rows});

  final List<_AddMenuRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Divider(color: colors.toasterBackground, height: 1),
          ),
        );
      }
      children.add(rows[i]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _AddMenuRow extends StatelessWidget {
  const _AddMenuRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorsV2 colors = context.colors;
    final AppTextTheme text = context.themeText;
    const containerSize = 40.0;
    const iconSize = 20.0;

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
