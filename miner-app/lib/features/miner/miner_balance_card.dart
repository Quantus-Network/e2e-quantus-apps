import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/services/miner_wallet_service.dart';
import 'package:quantus_miner/src/services/transfer_tracking_service.dart';
import 'package:quantus_miner/src/services/wormhole_address_manager.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart'
    hide WormholeAddressManager, TrackedWormholeAddress, WormholeAddressPurpose;

final _log = log.withTag('BalanceCard');

class MinerBalanceCard extends StatefulWidget {
  /// Current block number - when this changes, balance is refreshed
  final int currentBlock;

  /// Callback when withdraw button is pressed
  final void Function(BigInt balance, String address, String secretHex)? onWithdraw;

  /// Increment this to force a balance refresh (e.g., after withdrawal)
  final int refreshKey;

  const MinerBalanceCard({super.key, this.currentBlock = 0, this.onWithdraw, this.refreshKey = 0});

  @override
  State<MinerBalanceCard> createState() => _MinerBalanceCardState();
}

class _MinerBalanceCardState extends State<MinerBalanceCard> {
  final _walletService = MinerWalletService();
  final _addressManager = WormholeAddressManager();
  final _transferTrackingService = TransferTrackingService();

  String _rewardsBalance = 'Loading...';
  String? _wormholeAddress;
  String? _secretHex;
  BigInt _balancePlanck = BigInt.zero;
  int _unspentTransferCount = 0;
  bool _canTrackBalance = false;
  bool _canWithdraw = false;
  bool _isLoading = true;
  Timer? _balanceTimer;
  int _lastRefreshedBlock = 0;

  @override
  void initState() {
    super.initState();
    _loadWalletAndBalance();
    // Poll every 30 seconds for balance updates
    _balanceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchBalance();
    });
  }

  @override
  void didUpdateWidget(MinerBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh balance when block number increases (new block found)
    if (widget.currentBlock > _lastRefreshedBlock && widget.currentBlock > 0) {
      _lastRefreshedBlock = widget.currentBlock;
      _fetchBalance();
    }
    // Refresh balance when refreshKey changes (e.g., after withdrawal)
    if (widget.refreshKey != oldWidget.refreshKey) {
      _fetchBalance();
    }
  }

  @override
  void dispose() {
    _balanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWalletAndBalance() async {
    setState(() => _isLoading = true);

    try {
      // Ensure RPC endpoint is configured for the current chain
      final settingsService = MinerSettingsService();
      final chainId = await settingsService.getChainId();
      _log.i('Loading balance with chain: $chainId');

      // Check if we have a mnemonic (can derive secret for balance tracking)
      final canWithdraw = await _walletService.canWithdraw();
      _canTrackBalance = canWithdraw;

      if (canWithdraw) {
        // We have the mnemonic - get the full key pair
        final keyPair = await _walletService.getWormholeKeyPair();
        if (keyPair != null) {
          _wormholeAddress = keyPair.address;
          _secretHex = keyPair.secretHex;
          _canWithdraw = true;
          await _fetchBalanceWithSecret(keyPair.address, keyPair.secretHex);
        } else {
          _handleNotSetup();
        }
      } else {
        // Only preimage - we can show the address but not track balance
        final preimage = await _walletService.readRewardsPreimageFile();
        if (preimage != null) {
          // We have a preimage but can't derive the address without the secret
          setState(() {
            _wormholeAddress = null;
            _rewardsBalance = 'Import wallet to track';
            _isLoading = false;
          });
        } else {
          _handleNotSetup();
        }
      }
    } catch (e) {
      _log.e('Error loading wallet', error: e);
      setState(() {
        _rewardsBalance = 'Error';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBalance() async {
    if (!_canTrackBalance) return;

    try {
      final keyPair = await _walletService.getWormholeKeyPair();
      if (keyPair != null) {
        await _fetchBalanceWithSecret(keyPair.address, keyPair.secretHex);
      }
    } catch (e) {
      _log.w('Error fetching balance', error: e);
    }
  }

  Future<void> _fetchBalanceWithSecret(String address, String secretHex) async {
    try {
      // Initialize address manager and transfer tracking
      await _addressManager.initialize();

      // Get chain config for RPC URL
      final settingsService = MinerSettingsService();
      final chainConfig = await settingsService.getChainConfig();

      // Initialize transfer tracking with all known addresses
      final allAddresses = _addressManager.allAddressStrings;
      if (allAddresses.isEmpty) {
        _transferTrackingService.initialize(rpcUrl: chainConfig.rpcUrl, wormholeAddresses: {address});
      } else {
        _transferTrackingService.initialize(rpcUrl: chainConfig.rpcUrl, wormholeAddresses: allAddresses);
      }
      await _transferTrackingService.loadFromDisk();

      _log.i('=== BALANCE QUERY DEBUG ===');
      _log.i('Primary address (SS58): $address');
      _log.i('Total tracked addresses: ${_addressManager.allAddresses.length}');
      _log.i('===========================');

      // Get unspent transfers for all tracked addresses
      var totalBalance = BigInt.zero;
      var totalUnspentCount = 0;

      // Check primary address
      final primaryUnspent = await _transferTrackingService.getUnspentTransfers(
        wormholeAddress: address,
        secretHex: secretHex,
      );
      for (final transfer in primaryUnspent) {
        totalBalance += transfer.amount;
        totalUnspentCount++;
      }
      _log.i('Primary address: ${primaryUnspent.length} unspent, ${_formatBalance(totalBalance)}');

      // Check other tracked addresses (change addresses)
      for (final tracked in _addressManager.allAddresses) {
        if (tracked.address == address) continue; // Skip primary, already counted

        final unspent = await _transferTrackingService.getUnspentTransfers(
          wormholeAddress: tracked.address,
          secretHex: tracked.secretHex,
        );
        for (final transfer in unspent) {
          totalBalance += transfer.amount;
          totalUnspentCount++;
        }
        if (unspent.isNotEmpty) {
          final addrBalance = unspent.fold<BigInt>(BigInt.zero, (sum, t) => sum + t.amount);
          _log.i('Change address ${tracked.address}: ${unspent.length} unspent, ${_formatBalance(addrBalance)}');
        }
      }

      _log.i('Total withdrawable: $totalUnspentCount UTXOs, ${_formatBalance(totalBalance)}');

      if (mounted) {
        setState(() {
          _rewardsBalance = NumberFormattingService().formatBalance(totalBalance, addSymbol: true);
          _wormholeAddress = address;
          _secretHex = secretHex;
          _balancePlanck = totalBalance;
          _unspentTransferCount = totalUnspentCount;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      _log.e('Error fetching balance', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _rewardsBalance = 'Unable to connect';
          _isLoading = false;
        });
      }
    }
  }

  String _formatBalance(BigInt planck) {
    return NumberFormattingService().formatBalance(planck, addSymbol: true);
  }

  void _handleNotSetup() {
    if (mounted) {
      setState(() {
        _rewardsBalance = 'Not configured';
        _wormholeAddress = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (_isLoading)
              const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Text(
                _rewardsBalance,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  letterSpacing: -1,
                ),
              ),
            if (_wormholeAddress != null) ...[
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
                        _wormholeAddress!,
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
                      onPressed: () {
                        if (_wormholeAddress != null) {
                          context.copyTextWithSnackbar(_wormholeAddress!);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
            if (!_canTrackBalance && !_isLoading) ...[
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
            if (_canWithdraw && _balancePlanck > BigInt.zero && !_isLoading) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onWithdraw != null && _wormholeAddress != null && _secretHex != null) {
                      widget.onWithdraw!(_balancePlanck, _wormholeAddress!, _secretHex!);
                    }
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
