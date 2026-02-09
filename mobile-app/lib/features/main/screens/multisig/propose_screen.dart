import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:resonance_network_wallet/providers/wallet_providers.dart';

class ProposeScreen extends ConsumerStatefulWidget {
  const ProposeScreen({super.key});

  @override
  ConsumerState<ProposeScreen> createState() => _ProposeScreenState();
}

class _ProposeScreenState extends ConsumerState<ProposeScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final SubstrateService _substrateService = SubstrateService();
  final BalancesService _balancesService = BalancesService();
  final MultisigService _multisigService = MultisigService();
  final NumberFormattingService _numberFormatting = NumberFormattingService();
  final HumanReadableChecksumService _checksumService = HumanReadableChecksumService();

  String _checkphrase = '';
  String? _addressError;
  String? _amountError;
  BigInt _networkFee = BigInt.zero;
  bool _isFetchingFee = false;
  bool _isSubmitting = false;
  int _expiryBlocks = 7200; // ~24h at 12s blocks
  Timer? _debounce;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _recipientController.addListener(_onInputChanged);
    _amountController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _fetchFee);
  }

  Future<void> _validateAddress(String address) async {
    if (address.isEmpty) {
      setState(() {
        _addressError = null;
        _checkphrase = '';
      });
      return;
    }

    if (!_substrateService.isValidSS58Address(address)) {
      setState(() {
        _addressError = 'Invalid address';
        _checkphrase = '';
      });
      return;
    }

    final name = await _checksumService.getHumanReadableName(address);
    setState(() {
      _addressError = null;
      _checkphrase = name;
    });
  }

  Future<void> _fetchFee() async {
    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();

    await _validateAddress(recipient);
    if (_addressError != null || recipient.isEmpty || amountText.isEmpty) return;

    final amount = _parseAmount(amountText);
    if (amount == null || amount == BigInt.zero) return;

    final activeAccount = ref.read(activeAccountProvider).value;
    if (activeAccount is! MultisigDisplayAccount) return;

    final accounts = ref.read(accountsProvider).value ?? [];
    final signerAccount = _findSigner(accounts, activeAccount.account);
    if (signerAccount == null) return;

    setState(() => _isFetchingFee = true);
    try {
      final call = _balancesService.getBalanceTransferCall(recipient, amount);
      final encodedCall = call.encode();
      final currentBlock = await _multisigService.getCurrentBlockNumber();
      final expiry = currentBlock + _expiryBlocks;

      final feeData = await _multisigService.getProposeFee(
        signer: signerAccount,
        multisigAddress: activeAccount.account.accountId,
        encodedCall: encodedCall,
        expiry: expiry,
      );
      setState(() => _networkFee = feeData.fee);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isFetchingFee = false);
    }
  }

  BigInt? _parseAmount(String text) {
    try {
      final parts = text.split('.');
      final whole = BigInt.parse(parts[0]);
      BigInt fraction = BigInt.zero;
      if (parts.length > 1) {
        final fracStr = parts[1].padRight(12, '0').substring(0, 12);
        fraction = BigInt.parse(fracStr);
      }
      return whole * BigInt.from(10).pow(12) + fraction;
    } catch (_) {
      return null;
    }
  }

  Account? _findSigner(List<Account> accounts, MultisigAccount msig) {
    for (final account in accounts) {
      if (msig.signers.contains(account.accountId)) return account;
    }
    return null;
  }

  bool get _isValid {
    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();
    if (recipient.isEmpty || amountText.isEmpty || _addressError != null) return false;
    final amount = _parseAmount(amountText);
    return amount != null && amount > BigInt.zero;
  }

  Future<void> _propose() async {
    if (!_isValid) return;

    final activeAccount = ref.read(activeAccountProvider).value;
    if (activeAccount is! MultisigDisplayAccount) return;

    final accounts = ref.read(accountsProvider).value ?? [];
    final signerAccount = _findSigner(accounts, activeAccount.account);
    if (signerAccount == null) return;

    final recipient = _recipientController.text.trim();
    final amount = _parseAmount(_amountController.text.trim())!;

    setState(() => _isSubmitting = true);
    try {
      final call = _balancesService.getBalanceTransferCall(recipient, amount);
      final encodedCall = call.encode();
      final currentBlock = await _multisigService.getCurrentBlockNumber();
      final expiry = currentBlock + _expiryBlocks;

      await _multisigService.propose(
        signer: signerAccount,
        multisigAddress: activeAccount.account.accountId,
        encodedCall: encodedCall,
        expiry: expiry,
      );

      ref.invalidate(multisigProposalsProvider(activeAccount.account.accountId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal submitted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Propose failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);

    return ScaffoldBase(
      appBar: WalletAppBar(title: 'Propose Transfer'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            CustomTextField(
              controller: _recipientController,
              labelText: 'Recipient',
              hintText: 'Enter address',
              variant: TextFieldVariant.secondary,
              errorMsg: _addressError,
              trailing: IconButton(
                icon: const Icon(Icons.content_paste, color: Colors.white54, size: 20),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _recipientController.text = data!.text!;
                  }
                },
              ),
            ),
            if (_checkphrase.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _checkphrase,
                  style: context.themeText.detail?.copyWith(color: context.themeColors.checksum),
                ),
              ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _amountController,
              labelText: 'Amount',
              hintText: '0.00',
              variant: TextFieldVariant.secondary,
              errorMsg: _amountError,
              trailing: balanceAsync.when(
                data: (balance) => InkWell(
                  onTap: () {
                    _amountController.text = _numberFormatting.formatBalance(balance, addSymbol: false);
                  },
                  child: Text('MAX', style: context.themeText.detail?.copyWith(color: context.themeColors.checksum)),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 20),
            _buildExpirySelector(),
            const SizedBox(height: 20),
            _buildFeeRow(context),
            const SizedBox(height: 32),
            Button(
              label: _isSubmitting ? 'Submitting...' : 'Propose',
              variant: ButtonVariant.primary,
              isLoading: _isSubmitting,
              onPressed: (_isValid && !_isSubmitting) ? _propose : null,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expiry', style: context.themeText.detail?.copyWith(color: context.themeColors.inputLabel)),
        const SizedBox(height: 8),
        Row(
          children: [
            _expiryOption('1 hour', 300),
            const SizedBox(width: 8),
            _expiryOption('24 hours', 7200),
            const SizedBox(width: 8),
            _expiryOption('1 week', 50400),
            const SizedBox(width: 8),
            _expiryOption('2 weeks', 100800),
          ],
        ),
      ],
    );
  }

  Widget _expiryOption(String label, int blocks) {
    final isSelected = _expiryBlocks == blocks;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _expiryBlocks = blocks),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.themeColors.buttonNeutral : context.themeColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? context.themeColors.buttonNeutral : context.themeColors.borderLight),
          ),
          child: Center(
            child: Text(
              label,
              style: context.themeText.tiny?.copyWith(
                color: isSelected ? context.themeColors.textSecondary : context.themeColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeeRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Network Fee', style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted)),
        _isFetchingFee
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
              )
            : Text(
                _networkFee > BigInt.zero
                    ? '${_numberFormatting.formatBalance(_networkFee)} ${AppConstants.tokenSymbol}'
                    : '--',
                style: context.themeText.detail,
              ),
      ],
    );
  }
}
