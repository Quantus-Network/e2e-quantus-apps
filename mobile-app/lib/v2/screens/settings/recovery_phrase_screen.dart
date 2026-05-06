import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/components/recovery_phrase_body.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  const RecoveryPhraseScreen({super.key, this.walletIndex = 0});

  final int walletIndex;

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  final _settingsService = SettingsService();
  List<String> _words = [];

  void _loadMnemonic() async {
    final mnemonic = await _settingsService.getMnemonic(widget.walletIndex);
    if (mnemonic != null && mounted) {
      setState(() {
        _words = mnemonic.split(' ');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  @override
  Widget build(BuildContext context) {
    return RecoveryPhraseBody(
      appBarTitle: 'Recovery Phrase',
      words: _words,
      primaryButtonLabel: 'Done',
      onPrimary: () => Navigator.of(context).pop(),
    );
  }
}
