import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/account_tag.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/main/screens/multisig/call_decoder.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/multisig_providers.dart';

class ProposalDetailScreen extends ConsumerStatefulWidget {
  final String multisigAddress;
  final int proposalId;

  const ProposalDetailScreen({
    super.key,
    required this.multisigAddress,
    required this.proposalId,
  });

  @override
  ConsumerState<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends ConsumerState<ProposalDetailScreen> {
  final MultisigService _multisigService = MultisigService();
  final HumanReadableChecksumService _checksumService = HumanReadableChecksumService();
  final NumberFormattingService _numberFormatting = NumberFormattingService();

  bool _isSubmitting = false;

  Future<void> _approve() async {
    final activeAccount = ref.read(activeAccountProvider).value;
    if (activeAccount == null) return;

    final accounts = ref.read(accountsProvider).value ?? [];
    final signerAccount = _findSignerAccount(accounts, activeAccount);
    if (signerAccount == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _multisigService.approve(
        signer: signerAccount,
        multisigAddress: widget.multisigAddress,
        proposalId: widget.proposalId,
      );
      ref.invalidate(multisigProposalsProvider(widget.multisigAddress));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancel() async {
    final activeAccount = ref.read(activeAccountProvider).value;
    if (activeAccount == null) return;

    final accounts = ref.read(accountsProvider).value ?? [];
    final signerAccount = _findSignerAccount(accounts, activeAccount);
    if (signerAccount == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _multisigService.cancel(
        signer: signerAccount,
        multisigAddress: widget.multisigAddress,
        proposalId: widget.proposalId,
      );
      ref.invalidate(multisigProposalsProvider(widget.multisigAddress));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancel failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Account? _findSignerAccount(List<Account> accounts, DisplayAccount active) {
    if (active is! MultisigDisplayAccount) return null;
    final msig = active.account;
    for (final account in accounts) {
      if (msig.signers.contains(account.accountId)) return account;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final proposalAsync = ref.watch(multisigProposalsProvider(widget.multisigAddress));
    final multisigDataAsync = ref.watch(activeMultisigDataProvider(widget.multisigAddress));
    final blockNumberAsync = ref.watch(currentBlockNumberProvider);
    final activeAccount = ref.watch(activeAccountProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? [];

    return ScaffoldBase(
      appBar: WalletAppBar(title: 'Proposal #${widget.proposalId}'),
      child: proposalAsync.when(
        data: (proposals) {
          final match = proposals.where((p) => p.$1 == widget.proposalId);
          if (match.isEmpty) {
            return Center(
              child: Text('Proposal not found', style: context.themeText.smallParagraph),
            );
          }

          final proposal = match.first.$2;
          final currentBlock = blockNumberAsync.value ?? 0;
          final isExpired = currentBlock > proposal.expiry;
          final multisigData = multisigDataAsync.value;
          final signers = multisigData?.signers ?? [];
          final threshold = multisigData?.threshold ?? 0;

          final proposerAddress = _multisigService.signerToAddress(proposal.proposer);
          final userSignerAccount = activeAccount != null ? _findSignerAccount(accounts, activeAccount) : null;
          final isProposer = userSignerAccount != null && userSignerAccount.accountId == proposerAddress;
          final hasApproved = userSignerAccount != null &&
              proposal.approvals.any((a) =>
                _multisigService.signerToAddress(a) == userSignerAccount.accountId);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: 'Details',
                  children: [
                    _buildRow(context, 'Proposer', AddressFormattingService.formatAddress(proposerAddress)),
                    _buildRow(context, 'Threshold', '$threshold of ${signers.length} required'),
                    _buildRow(
                      context,
                      'Expiry',
                      isExpired ? 'Expired' : 'Block #${proposal.expiry}',
                      valueColor: isExpired ? context.themeColors.buttonDanger : null,
                    ),
                    _buildRow(context, 'Approvals', '${proposal.approvals.length} of $threshold'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTransactionSection(context, proposal),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: 'Signers',
                  children: signers.map((signer) {
                    final signerAddr = _multisigService.signerToAddress(signer);
                    final approved = proposal.approvals.any((a) =>
                      _multisigService.signerToAddress(a) == signerAddr);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            approved ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: approved
                                ? context.themeColors.buttonSuccess
                                : context.themeColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _checksumService.getHumanReadableName(signerAddr),
                              builder: (context, snap) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (snap.data != null)
                                      Text(
                                        snap.data!,
                                        style: context.themeText.detail?.copyWith(
                                          color: context.themeColors.checksum,
                                        ),
                                      ),
                                    Text(
                                      AddressFormattingService.formatAddress(signerAddr),
                                      style: context.themeText.tiny?.copyWith(
                                        color: context.themeColors.textMuted,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (approved)
                            AccountTag(text: 'Approved', color: context.themeColors.buttonSuccess),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                if (!isExpired && !hasApproved)
                  Button(
                    label: 'Approve',
                    variant: ButtonVariant.primary,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _approve,
                  ),
                if (!isExpired && hasApproved)
                  const Button(
                    label: 'Already Approved',
                    variant: ButtonVariant.glass,
                    isDisabled: true,
                    onPressed: null,
                  ),
                if (isProposer && !isExpired) ...[
                  const SizedBox(height: 12),
                  Button(
                    label: 'Cancel Proposal',
                    variant: ButtonVariant.dangerOutline,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _cancel,
                  ),
                ],
                if (isExpired)
                  const Button(
                    label: 'Proposal Expired',
                    variant: ButtonVariant.glass,
                    isDisabled: true,
                    onPressed: null,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: context.themeText.detail?.copyWith(color: context.themeColors.textError)),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.themeColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.themeText.smallParagraph?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: context.themeText.detail?.copyWith(color: valueColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(BuildContext context, ProposalData proposal) {
    final decoded = decodeTransferCall(proposal.call);

    return _buildSection(
      context,
      title: 'Transaction',
      children: [
        if (decoded != null) ...[
          _buildRow(context, 'Type', 'Transfer'),
          _buildRow(
            context,
            'Amount',
            '${_numberFormatting.formatBalance(decoded.amount)} ${AppConstants.tokenSymbol}',
          ),
          _buildRow(context, 'To', AddressFormattingService.formatAddress(decoded.destination)),
        ] else
          _buildRow(context, 'Type', 'Unknown call (${proposal.call.length} bytes)'),
      ],
    );
  }
}

