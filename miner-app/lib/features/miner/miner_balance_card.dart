import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/miner_state_service.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

/// Card widget displaying mining rewards balance.
///
/// Uses [MinerStateService] streams for reactive updates - no local state duplication.
/// Balance updates automatically when:
/// - New blocks are mined (transfers tracked)
/// - Session starts/stops
/// - Withdrawals complete
class MinerBalanceCard extends StatefulWidget {
  /// Callback when withdraw button is pressed
  final void Function(BigInt balance, String address, String secretHex)? onWithdraw;

  const MinerBalanceCard({super.key, this.onWithdraw});

  @override
  State<MinerBalanceCard> createState() => _MinerBalanceCardState();
}

class _MinerBalanceCardState extends State<MinerBalanceCard> {
  final _stateService = MinerStateService();

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to reactively update when balance changes
    return StreamBuilder<BalanceState>(
      stream: _stateService.balanceStream,
      initialData: BalanceState(
        balance: _stateService.balance,
        unspentCount: _stateService.unspentCount,
        canWithdraw: _stateService.canWithdraw,
      ),
      builder: (context, snapshot) {
        final balanceState = snapshot.data ?? BalanceState(balance: BigInt.zero, unspentCount: 0, canWithdraw: false);

        return _buildCard(
          balance: balanceState.balance,
          canWithdraw: balanceState.canWithdraw,
          isSessionActive: _stateService.isSessionActive,
        );
      },
    );
  }

  Widget _buildCard({required BigInt balance, required bool canWithdraw, required bool isSessionActive}) {
    final address = _stateService.wormholeAddress;
    final secretHex = _stateService.secretHex;
    final formattedBalance = NumberFormattingService().formatBalance(balance, addSymbol: true);

    // Determine display state
    String displayBalance;
    bool showWithdrawButton = false;
    bool showNotConfigured = false;

    if (address == null) {
      displayBalance = 'Not configured';
      showNotConfigured = true;
    } else if (!isSessionActive) {
      displayBalance = '0 QTN';
    } else {
      displayBalance = formattedBalance;
      showWithdrawButton = canWithdraw;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.savings, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mining Rewards',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balance display
            Text(
              displayBalance,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
                letterSpacing: -1,
              ),
            ),

            // Address display
            if (address != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.white.withValues(alpha: 0.5), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: 'Fira Code',
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.white.withValues(alpha: 0.5), size: 16),
                      onPressed: () => context.copyTextWithSnackbar(address),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],

            // Not configured warning
            if (showNotConfigured) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade300, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Import your full wallet to track balance and withdraw rewards.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade200),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Withdraw button
            if (showWithdrawButton && address != null && secretHex != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onWithdraw?.call(balance, address, secretHex);
                  },
                  icon: const Icon(Icons.output, size: 18),
                  label: const Text('Withdraw Rewards'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
