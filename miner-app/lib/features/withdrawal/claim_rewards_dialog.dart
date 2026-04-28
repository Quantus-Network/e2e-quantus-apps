import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/binary_manager.dart';
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/services/miner_wallet_service.dart';
import 'package:quantus_miner/src/services/wormhole_claim_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';

final _log = log.withTag('ClaimDialog');

Future<void> showClaimRewardsDialog({required BuildContext context, required BigInt balance}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ClaimRewardsDialog(balance: balance),
  );
}

class _ClaimRewardsDialog extends StatefulWidget {
  final BigInt balance;
  const _ClaimRewardsDialog({required this.balance});

  @override
  State<_ClaimRewardsDialog> createState() => _ClaimRewardsDialogState();
}

enum _Screen { input, confirm, progress }

class _ClaimRewardsDialogState extends State<_ClaimRewardsDialog> {
  final _addressController = TextEditingController();
  final _claimService = WormholeClaimService();
  final _walletService = MinerWalletService();
  final _settingsService = MinerSettingsService();

  _Screen _screen = _Screen.input;
  String? _addressError;
  final List<String> _progressLogs = [];
  bool _running = false;
  bool _done = false;
  String? _errorMessage;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatBalance(BigInt planck) {
    final whole = planck ~/ BigInt.from(10).pow(12);
    final frac = (planck % BigInt.from(10).pow(12)).toString().padLeft(12, '0').substring(0, 4);
    return '$whole.$frac';
  }

  bool _validateAddress(String address) {
    if (address.trim().isEmpty) {
      setState(() => _addressError = 'Please enter a destination address');
      return false;
    }
    if (address.trim().length < 40) {
      setState(() => _addressError = 'Invalid address format');
      return false;
    }
    setState(() => _addressError = null);
    return true;
  }

  void _goToConfirm() {
    if (!_validateAddress(_addressController.text)) return;
    setState(() => _screen = _Screen.confirm);
  }

  void _goBack() {
    setState(() {
      _screen = _Screen.input;
      _addressError = null;
    });
  }

  Future<void> _startClaim() async {
    setState(() {
      _screen = _Screen.progress;
      _running = true;
      _done = false;
      _errorMessage = null;
      _progressLogs.clear();
    });

    try {
      final keyPair = await _walletService.getWormholeKeyPair();
      if (keyPair == null || keyPair.secretHex.isEmpty) {
        throw StateError('Wormhole key pair not available');
      }

      final chainConfig = await _settingsService.getChainConfig();
      final binsDir = '${await BinaryManager.getQuantusHomeDirectoryPath()}/generated-bins';
      await Directory(binsDir).create(recursive: true);

      final rpcUrl = chainConfig.rpcUrl;

      _addLog('Starting claim for ${keyPair.address}');
      _addLog('Destination: ${_addressController.text.trim()}');
      _addLog('RPC: $rpcUrl');
      _addLog('');

      final result = await _claimService.claimRewards(
        wormholeAddress: keyPair.address,
        secretHex: keyPair.secretHex,
        destinationAddress: _addressController.text.trim(),
        rpcUrl: rpcUrl,
        circuitBinsDir: binsDir,
        onProgress: (step, detail, {int? current, int? total}) {
          if (!mounted) return;
          _addLog(detail);
        },
      );

      if (!mounted) return;
      setState(() {
        _done = true;
        _running = false;
      });
      _addLog('');
      _addLog('Done! ${result.transfersProcessed} transfers claimed in ${result.batchesSubmitted} batch(es)');
    } on StateError catch (e) {
      if (e.message.contains('cancelled')) {
        _addLog('');
        _addLog('Cancelled by user');
        if (!mounted) return;
        setState(() {
          _running = false;
          _done = true;
        });
      } else {
        _log.e('Claim failed', error: e);
        _addLog('');
        _addLog('ERROR: ${e.message}');
        if (!mounted) return;
        setState(() {
          _running = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      _log.e('Claim failed', error: e);
      _addLog('');
      _addLog('ERROR: $e');
      if (!mounted) return;
      setState(() {
        _running = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _addLog(String line) {
    if (!mounted) return;
    setState(() => _progressLogs.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelClaim() {
    _claimService.cancel();
    _addLog('Cancelling...');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 540,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (_screen) {
            _Screen.input => _buildInputScreen(),
            _Screen.confirm => _buildConfirmScreen(),
            _Screen.progress => _buildProgressScreen(),
          },
        ),
      ),
    );
  }

  Widget _buildInputScreen() {
    return Padding(
      key: const ValueKey('input'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Claim Rewards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Claimable Balance', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                Text(
                  '${_formatBalance(widget.balance)} QUAN',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF10B981), fontFamily: 'Fira Code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Destination Address', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Fira Code', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter a Quantus address...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              errorText: _addressError,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _goToConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Claim All Rewards', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmScreen() {
    return Padding(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: Colors.amber.shade300, size: 24),
              const SizedBox(width: 12),
              const Text('Confirm Withdrawal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          _confirmRow('Amount', '${_formatBalance(widget.balance)} QUAN'),
          const SizedBox(height: 12),
          _confirmRow('Destination', _addressController.text.trim(), mono: true),
          const SizedBox(height: 12),
          _confirmRow('Fee', '0.1% volume fee'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade300, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ZK proof generation may take several minutes. Do not close the app.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _goBack,
                child: Text('Back', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _startClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool mono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontFamily: mono ? 'Fira Code' : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressScreen() {
    return Padding(
      key: const ValueKey('progress'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_running)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
              else if (_errorMessage != null)
                const Icon(Icons.error_outline, color: Colors.red, size: 20)
              else
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 12),
              Text(
                _running
                    ? 'Claiming Rewards...'
                    : _errorMessage != null
                        ? 'Claim Failed'
                        : 'Claim Complete',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _progressLogs.length,
              itemBuilder: (context, index) {
                final line = _progressLogs[index];
                final isError = line.startsWith('ERROR');
                final isEmpty = line.isEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    isEmpty ? '' : line,
                    style: TextStyle(
                      color: isError ? Colors.red.shade300 : const Color(0xFF7CE38B),
                      fontFamily: 'Courier',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_running)
                TextButton(
                  onPressed: _cancelClaim,
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                )
              else ...[
                if (_errorMessage != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _screen = _Screen.confirm;
                        _errorMessage = null;
                      });
                    },
                    child: const Text('Retry', style: TextStyle(color: Color(0xFF10B981))),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _done && _errorMessage == null ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
