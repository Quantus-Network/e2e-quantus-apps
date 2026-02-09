import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/custom_text_field.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/multisig_providers.dart';

class CreateMultisigScreen extends ConsumerStatefulWidget {
  const CreateMultisigScreen({super.key});

  @override
  ConsumerState<CreateMultisigScreen> createState() => _CreateMultisigScreenState();
}

class _CreateMultisigScreenState extends ConsumerState<CreateMultisigScreen> {
  final TextEditingController _signerController = TextEditingController();
  final SubstrateService _substrateService = SubstrateService();
  final MultisigService _multisigService = MultisigService();
  final HumanReadableChecksumService _checksumService = HumanReadableChecksumService();

  final List<String> _signers = [];
  int _threshold = 2;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = ref.read(accountsProvider).value ?? [];
      if (accounts.isNotEmpty) {
        setState(() => _signers.add(accounts.first.accountId));
      }
    });
  }

  @override
  void dispose() {
    _signerController.dispose();
    super.dispose();
  }

  void _addSigner() {
    final address = _signerController.text.trim();
    if (address.isEmpty) return;
    if (!_substrateService.isValidSS58Address(address)) {
      setState(() => _error = 'Invalid address');
      return;
    }
    if (_signers.contains(address)) {
      setState(() => _error = 'Already added');
      return;
    }
    setState(() {
      _signers.add(address);
      _error = null;
      _signerController.clear();
      if (_threshold > _signers.length) _threshold = _signers.length;
    });
  }

  Future<void> _create() async {
    if (_signers.length < 2) {
      setState(() => _error = 'Need at least 2 signers');
      return;
    }

    final accounts = ref.read(accountsProvider).value ?? [];
    final signerAccount = accounts.firstWhere(
      (a) => _signers.contains(a.accountId),
      orElse: () => accounts.first,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final nonce = BigInt.from(DateTime.now().millisecondsSinceEpoch);

      await _multisigService.createMultisig(
        signer: signerAccount,
        signerAddresses: _signers,
        threshold: _threshold,
        nonce: nonce,
      );

      final derivedAddress = _multisigService.deriveMultisigAddress(
        signerAddresses: _signers,
        threshold: _threshold,
        nonce: nonce,
      );

      final account = MultisigAccount(
        name: 'Multisig',
        accountId: derivedAddress,
        signers: List.of(_signers),
        threshold: _threshold,
      );

      await _multisigService.saveMultisigAccount(account);
      ref.invalidate(multisigAccountsProvider);
      await ref.read(activeAccountProvider.notifier).setActiveAccount(MultisigDisplayAccount(account));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Creation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldBase(
      appBar: WalletAppBar(title: 'Create Multisig'),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Signers', style: context.themeText.detail?.copyWith(color: context.themeColors.inputLabel)),
                  const SizedBox(height: 12),
                  ..._signers.asMap().entries.map((entry) => _buildSignerItem(entry.key, entry.value)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _signerController,
                    hintText: 'Add signer address',
                    variant: TextFieldVariant.secondary,
                    errorMsg: _error,
                    trailing: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white54),
                      onPressed: _addSigner,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Threshold', style: context.themeText.detail?.copyWith(color: context.themeColors.inputLabel)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      _signers.length,
                      (i) {
                        final val = i + 1;
                        final isSelected = _threshold == val;
                        return InkWell(
                          onTap: () => setState(() => _threshold = val),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? context.themeColors.buttonNeutral : context.themeColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? context.themeColors.buttonNeutral : context.themeColors.borderLight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$val',
                                style: context.themeText.smallParagraph?.copyWith(
                                  color: isSelected ? context.themeColors.textSecondary : context.themeColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$_threshold of ${_signers.length} signers required',
                      style: context.themeText.tiny?.copyWith(color: context.themeColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Button(
            label: _isLoading ? 'Creating...' : 'Create Multisig',
            variant: ButtonVariant.primary,
            isLoading: _isLoading,
            onPressed: (_signers.length >= 2 && !_isLoading) ? _create : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSignerItem(int index, String address) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${index + 1}.',
              style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.themeColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.themeColors.borderLight),
              ),
              child: FutureBuilder<String>(
                future: _checksumService.getHumanReadableName(address),
                builder: (context, snap) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AddressFormattingService.formatAddress(address),
                        style: context.themeText.detail,
                      ),
                      if (snap.data != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            snap.data!,
                            style: context.themeText.tiny?.copyWith(color: context.themeColors.checksum),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_signers.length > 1)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: context.themeColors.textMuted),
              onPressed: () => setState(() {
                _signers.removeAt(index);
                if (_threshold > _signers.length) _threshold = _signers.length;
              }),
            ),
        ],
      ),
    );
  }
}
