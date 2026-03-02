import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/services/miner_wallet_service.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('BalanceCard');

class MinerBalanceCard extends StatefulWidget {
  /// Current block number - when this changes, balance is refreshed
  final int currentBlock;

  /// Callback when withdraw button is pressed
  final void Function(BigInt balance, String address, String secretHex)? onWithdraw;

  const MinerBalanceCard({super.key, this.currentBlock = 0, this.onWithdraw});

  @override
  State<MinerBalanceCard> createState() => _MinerBalanceCardState();
}

class _MinerBalanceCardState extends State<MinerBalanceCard> {
  final _walletService = MinerWalletService();
  final _substrateService = SubstrateService();

  String _rewardsBalance = 'Loading...';
  String? _wormholeAddress;
  String? _secretHex;
  BigInt _balancePlanck = BigInt.zero;
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
      // Get the full keypair to log hex address
      final keyPair = await _walletService.getWormholeKeyPair();
      _log.i('=== BALANCE QUERY DEBUG ===');
      _log.i('Address (SS58): $address');
      if (keyPair != null) {
        _log.i('Address (hex):  ${keyPair.addressHex}');
      }
      _log.i('RPC endpoint: ${RpcEndpointService().bestEndpointUrl}');
      _log.i('===========================');

      // Use raw RPC to avoid metadata mismatch with local dev chain
      final balance = await _substrateService.queryBalanceRaw(address);

      _log.i('Got balance: $balance planck');

      if (mounted) {
        setState(() {
          _rewardsBalance = NumberFormattingService().formatBalance(balance, addSymbol: true);
          _wormholeAddress = address;
          _balancePlanck = balance;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      _log.e('Error fetching balance', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _rewardsBalance = 'RPC unavailable';
          _isLoading = false;
        });
      }
    }
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
