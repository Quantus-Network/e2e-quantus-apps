import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/main/screens/multisig/call_decoder.dart';
import 'package:resonance_network_wallet/features/main/screens/multisig/proposal_detail_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/multisig_providers.dart';

class MultisigProposalsSection extends ConsumerWidget {
  final String multisigAddress;

  const MultisigProposalsSection({super.key, required this.multisigAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(multisigProposalsProvider(multisigAddress));
    final blockNumberAsync = ref.watch(currentBlockNumberProvider);

    return proposalsAsync.when(
      data: (proposals) {
        if (proposals.isEmpty) return const SizedBox.shrink();

        final currentBlock = blockNumberAsync.value ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
              child: Text(
                'Active Proposals',
                style: context.themeText.smallParagraph?.copyWith(color: context.themeColors.light),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(color: Colors.black.withAlpha(128), borderRadius: BorderRadius.circular(5)),
              child: Column(
                children: proposals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final (proposalId, proposal) = entry.value;
                  final isExpired = currentBlock > proposal.expiry;

                  return Column(
                    children: [
                      if (index > 0) Divider(color: context.themeColors.darkGray, thickness: 0.5, height: 24),
                      _ProposalListItem(
                        proposalId: proposalId,
                        proposal: proposal,
                        isExpired: isExpired,
                        multisigAddress: multisigAddress,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ProposalListItem extends StatelessWidget {
  final int proposalId;
  final ProposalData proposal;
  final bool isExpired;
  final String multisigAddress;

  const _ProposalListItem({
    required this.proposalId,
    required this.proposal,
    required this.isExpired,
    required this.multisigAddress,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormatting = NumberFormattingService();
    final decoded = decodeTransferCall(proposal.call);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProposalDetailScreen(multisigAddress: multisigAddress, proposalId: proposalId),
          ),
        );
      },
      child: Row(
        children: [
          Image.asset('assets/transaction/send_icon.png', width: 19, height: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proposal #$proposalId',
                      style: context.themeText.smallParagraph?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (decoded != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: numberFormatting.formatBalance(decoded.amount),
                              style: context.themeText.smallParagraph,
                            ),
                            TextSpan(text: ' ${AppConstants.tokenSymbol}', style: context.themeText.tiny),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${proposal.approvals.length} approvals',
                      style: context.themeText.tiny?.copyWith(color: context.themeColors.textMuted),
                    ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.themeColors.buttonDanger.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Expired',
                          style: context.themeText.tiny?.copyWith(color: context.themeColors.buttonDanger),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
