import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/custom_text_field.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/segmented_control.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/main/screens/multisig/create_multisig_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/multisig_providers.dart';

enum _AddMode { manual, discover }

class AddMultisigScreen extends ConsumerStatefulWidget {
  const AddMultisigScreen({super.key});

  @override
  ConsumerState<AddMultisigScreen> createState() => _AddMultisigScreenState();
}

class _AddMultisigScreenState extends ConsumerState<AddMultisigScreen> {
  final TextEditingController _addressController = TextEditingController();
  final SubstrateService _substrateService = SubstrateService();

  _AddMode _mode = _AddMode.manual;
  MultisigData? _multisigData;
  String? _error;
  bool _isLoading = false;
  List<MultisigAccount>? _discovered;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _lookupAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    if (!_substrateService.isValidSS58Address(address)) {
      setState(() => _error = 'Invalid address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _multisigData = null;
    });

    try {
      final service = ref.read(multisigServiceProvider);
      final data = await service.getMultisigData(address);
      setState(() {
        _multisigData = data;
        _error = data == null ? 'No multisig found at this address' : null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to lookup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addManual() async {
    if (_multisigData == null) return;
    final address = _addressController.text.trim();
    final service = ref.read(multisigServiceProvider);

    final signerAddresses = _multisigData!.signers
        .map((s) => service.signerToAddress(s))
        .toList();

    final account = MultisigAccount(
      name: 'Multisig',
      accountId: address,
      signers: signerAddresses,
      threshold: _multisigData!.threshold,
    );

    await service.saveMultisigAccount(account);
    ref.invalidate(multisigAccountsProvider);
    await ref.read(activeAccountProvider.notifier).setActiveAccount(MultisigDisplayAccount(account));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _discover() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _discovered = null;
    });

    try {
      final accounts = ref.read(accountsProvider).value ?? [];
      final userIds = accounts.map((a) => a.accountId).toList();
      final service = ref.read(multisigServiceProvider);
      final results = await service.discoverMultisigs(userIds);

      setState(() {
        _discovered = results;
        if (results.isEmpty) _error = 'No multisig wallets found for your accounts';
      });
    } catch (e) {
      setState(() => _error = 'Discovery failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDiscovered(MultisigAccount account) async {
    final service = ref.read(multisigServiceProvider);
    await service.saveMultisigAccount(account);
    ref.invalidate(multisigAccountsProvider);
    await ref.read(activeAccountProvider.notifier).setActiveAccount(MultisigDisplayAccount(account));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldBase(
      appBar: WalletAppBar(title: 'Add Multisig Wallet'),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SegmentedControl<_AddMode>(
            items: const [
              SegmentedControlItem(value: _AddMode.manual, child: Text('Manual')),
              SegmentedControlItem(value: _AddMode.discover, child: Text('Discover')),
            ],
            selectedValue: _mode,
            onSelectionChanged: (value) => setState(() => _mode = value),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _mode == _AddMode.manual ? _buildManualTab() : _buildDiscoverTab(),
          ),
          Button(
            label: 'Create New Multisig',
            variant: ButtonVariant.glassOutline,
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateMultisigScreen()),
              );
              if (result == true && mounted) Navigator.pop(context, true);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _addressController,
          hintText: 'Enter multisig address',
          variant: TextFieldVariant.secondary,
          errorMsg: _error,
          trailing: IconButton(
            icon: const Icon(Icons.search, color: Colors.white54),
            onPressed: _isLoading ? null : _lookupAddress,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (_multisigData != null) ...[
          _buildMultisigInfo(_multisigData!),
          const Spacer(),
          Button(
            label: 'Add Multisig Wallet',
            variant: ButtonVariant.primary,
            onPressed: _addManual,
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        if (_discovered == null && !_isLoading) ...[
          Text(
            'Scan the network to find multisig wallets where your accounts are signers.',
            style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted),
          ),
          const SizedBox(height: 24),
          Button(
            label: 'Discover Multisigs',
            variant: ButtonVariant.glassOutline,
            onPressed: _discover,
          ),
        ],
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Colors.white),
          ),
        if (_error != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted)),
          ),
        if (_discovered != null && _discovered!.isNotEmpty)
          Expanded(
            child: ListView.separated(
              itemCount: _discovered!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msig = _discovered![index];
                return _buildDiscoveredItem(msig);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDiscoveredItem(MultisigAccount msig) {
    return InkWell(
      onTap: () => _addDiscovered(msig),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.themeColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.themeColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AddressFormattingService.formatAddress(msig.accountId),
              style: context.themeText.smallParagraph,
            ),
            const SizedBox(height: 4),
            Text(
              '${msig.threshold} of ${msig.signers.length} signers',
              style: context.themeText.detail?.copyWith(color: context.themeColors.accountTagMultisig),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultisigInfo(MultisigData data) {
    final service = ref.read(multisigServiceProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.themeColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Threshold: ${data.threshold} of ${data.signers.length}',
            style: context.themeText.smallParagraph?.copyWith(color: context.themeColors.accountTagMultisig),
          ),
          const SizedBox(height: 8),
          Text('Signers', style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted)),
          const SizedBox(height: 4),
          ...data.signers.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              AddressFormattingService.formatAddress(service.signerToAddress(s)),
              style: context.themeText.tiny,
            ),
          )),
        ],
      ),
    );
  }
}
