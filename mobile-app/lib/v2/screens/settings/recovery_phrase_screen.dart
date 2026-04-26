import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/mnemonic_grid.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  const RecoveryPhraseScreen({super.key, this.walletIndex = 0});

  final int walletIndex;

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  final _settingsService = SettingsService();
  List<String> _words = [];

  void _back() {
    Navigator.of(context).pop();
  }

  void _loadMnemonic() async {
    final mnemonic = await _settingsService.getMnemonic(widget.walletIndex);
    if (mnemonic != null && mounted) {
      setState(() {
        _words = mnemonic.split(' ');
      });
    }
  }

  void _copyToClipboard() {
    context.copyTextWithToaster(_words.join(' '), message: 'Recovery phrase copied to clipboard');
  }

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Recovery Phrase'),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Write these words down in order and keep them somewhere only you can access. Do not screenshot or copy to a notes app.',
            style: text.smallParagraph?.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(child: MnemonicGrid(words: _words, isRevealed: true)),
          ),
        ],
      ),
      bottomContent: _bottomBar(colors, text),
    );
  }

  Widget _bottomBar(AppColorsV2 colors, AppTextTheme text) {
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
            child: QuantusButton.simple(label: 'Done', onTap: _back, variant: ButtonVariant.primary),
          ),
        ],
      ),
    );
  }
}
