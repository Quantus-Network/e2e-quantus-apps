import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quantus_miner/src/services/miner_settings_service.dart';
import 'package:quantus_miner/src/services/transfer_tracking_service.dart';
import 'package:quantus_miner/src/services/withdrawal_service.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('Withdrawal');

/// Screen for withdrawing mining rewards from wormhole address.
class WithdrawalScreen extends StatefulWidget {
  /// Available balance in planck (12 decimals)
  final BigInt availableBalance;

  /// Wormhole address where rewards are stored
  final String wormholeAddress;

  /// Secret hex for proof generation
  final String secretHex;

  const WithdrawalScreen({
    super.key,
    required this.availableBalance,
    required this.wormholeAddress,
    required this.secretHex,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isWithdrawing = false;
  bool _withdrawAll = true;
  String? _error;
  double _progress = 0;
  String _statusMessage = '';

  // Circuit status
  final _circuitManager = CircuitManager();
  CircuitStatus _circuitStatus = CircuitStatus.unavailable;
  bool _isExtractingCircuits = false;

  // Transfer tracking
  final _transferTrackingService = TransferTrackingService();
  List<TrackedTransfer> _trackedTransfers = [];
  bool _hasLoadedTransfers = false;

  // Fee is 10 basis points (0.1%)
  static const int _feeBps = 10;

  @override
  void initState() {
    super.initState();
    // Default to max amount
    _updateAmountToMax();
    // Check circuit availability
    _checkCircuits();
    // Load tracked transfers
    _loadTrackedTransfers();
  }

  Future<void> _loadTrackedTransfers() async {
    try {
      // Initialize the tracking service with current chain config
      final settingsService = MinerSettingsService();
      final chainConfig = await settingsService.getChainConfig();

      _transferTrackingService.initialize(
        rpcUrl: chainConfig.rpcUrl,
        wormholeAddress: widget.wormholeAddress,
      );

      // Load from disk first
      await _transferTrackingService.loadFromDisk();

      // Get unspent transfers
      final transfers = await _transferTrackingService.getUnspentTransfers(
        wormholeAddress: widget.wormholeAddress,
        secretHex: widget.secretHex,
      );

      if (mounted) {
        setState(() {
          _trackedTransfers = transfers;
          _hasLoadedTransfers = true;
        });
      }

      _log.i('Loaded ${transfers.length} tracked transfers for withdrawal');
    } catch (e) {
      _log.e('Failed to load tracked transfers', error: e);
      if (mounted) {
        setState(() {
          _hasLoadedTransfers = true; // Mark as loaded even on error
        });
      }
    }
  }

  Future<void> _checkCircuits() async {
    final status = await _circuitManager.checkStatus();
    if (mounted) {
      setState(() {
        _circuitStatus = status;
      });
    }
  }

  Future<void> _extractCircuits() async {
    _log.i('Starting circuit extraction...');
    if (!mounted) return;

    setState(() {
      _isExtractingCircuits = true;
      _error = null;
      _progress = 0.1;
      _statusMessage = 'Extracting circuit files...';
    });

    bool success = false;
    try {
      final result = await _circuitManager.extractCircuitsFromAssets(
        onProgress: (progress, message) {
          _log.i('Circuit extraction progress: $progress - $message');
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusMessage = message;
            });
          }
        },
      );
      success = result;
      _log.i('Circuit extraction finished. Success: $success');
    } catch (e) {
      _log.e('Circuit extraction threw exception', error: e);
      success = false;
    }

    // Always update state after completion, regardless of success
    if (!mounted) {
      _log.w('Widget not mounted after circuit extraction');
      return;
    }

    // Check circuit status first
    final status = await _circuitManager.checkStatus();
    _log.i(
      'Circuit status after extraction: isAvailable=${status.isAvailable}, dir=${status.circuitDir}, size=${status.totalSizeBytes}',
    );

    if (!mounted) return;

    // Update all state in a single setState call
    setState(() {
      _isExtractingCircuits = false;
      _circuitStatus = status;
      if (success && status.isAvailable) {
        _progress = 1.0;
        _statusMessage = 'Circuit files ready!';
        _error = null;
      } else if (!success) {
        _error = 'Failed to extract circuit files. Please try again.';
      } else {
        _error = 'Extraction completed but verification failed. Missing files?';
      }
    });

    _log.i(
      'State updated: _isExtractingCircuits=$_isExtractingCircuits, _circuitStatus.isAvailable=${_circuitStatus.isAvailable}',
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmountToMax() {
    final formatted = NumberFormattingService().formatBalance(
      widget.availableBalance,
      addSymbol: false,
    );
    _amountController.text = formatted;
  }

  BigInt _parseAmount(String text) {
    try {
      // Remove any commas and parse
      final cleaned = text.replaceAll(',', '').trim();
      final parts = cleaned.split('.');

      BigInt wholePart = BigInt.parse(parts[0]);
      BigInt fractionalPart = BigInt.zero;

      if (parts.length > 1) {
        // Pad or truncate to 12 decimal places
        String fraction = parts[1].padRight(12, '0').substring(0, 12);
        fractionalPart = BigInt.parse(fraction);
      }

      // Convert to planck (12 decimal places)
      return wholePart * BigInt.from(10).pow(12) + fractionalPart;
    } catch (e) {
      return BigInt.zero;
    }
  }

  String? _validateDestination(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a destination address';
    }

    final trimmed = value.trim();

    // Quantus addresses (SS58 prefix 189) must start with "qz"
    if (!trimmed.startsWith('qz')) {
      return 'Address must start with "qz"';
    }

    // Check for valid base58 characters
    final base58Regex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
    if (!base58Regex.hasMatch(trimmed)) {
      return 'Invalid address format';
    }

    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final amount = _parseAmount(value);
    if (amount <= BigInt.zero) {
      return 'Amount must be greater than 0';
    }
    if (amount > widget.availableBalance) {
      return 'Amount exceeds available balance';
    }
    // Check minimum after fee
    final afterFee =
        amount - (amount * BigInt.from(_feeBps) ~/ BigInt.from(10000));
    // Minimum is 0.03 QTN (3 quantized units = 3 * 10^10 planck)
    final minAmount = BigInt.from(3) * BigInt.from(10).pow(10);
    if (afterFee < minAmount) {
      return 'Amount too small after fee (min ~0.03 QTN)';
    }
    return null;
  }

  Future<void> _startWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isWithdrawing = true;
      _error = null;
      _progress = 0;
      _statusMessage = 'Preparing withdrawal...';
    });

    try {
      final destination = _destinationController.text.trim();
      final amount = _withdrawAll
          ? widget.availableBalance
          : _parseAmount(_amountController.text);

      _log.i('Starting withdrawal of $amount planck to $destination');

      // Check circuit availability
      if (!_circuitStatus.isAvailable || _circuitStatus.circuitDir == null) {
        if (mounted) {
          context.showErrorSnackbar(
            title: 'Circuits Required',
            message: 'Please download circuit files first (~163MB).',
          );
        }
        return;
      }

      final withdrawalService = WithdrawalService();
      final circuitBinsDir = _circuitStatus.circuitDir!;

      // Check if we have tracked transfers (required for exact amounts)
      if (_trackedTransfers.isEmpty) {
        setState(() {
          _error =
              'No tracked transfers available. Mining rewards can only be '
              'withdrawn for blocks mined while the app was open.';
          _isWithdrawing = false;
        });
        return;
      }

      _log.i(
        'Using ${_trackedTransfers.length} tracked transfers with exact amounts',
      );

      final result = await withdrawalService.withdraw(
        secretHex: widget.secretHex,
        wormholeAddress: widget.wormholeAddress,
        destinationAddress: destination,
        amount: _withdrawAll ? null : amount,
        circuitBinsDir: circuitBinsDir,
        trackedTransfers: _trackedTransfers.isNotEmpty
            ? _trackedTransfers
            : null,
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusMessage = message;
            });
          }
        },
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Withdrawal successful! TX: ${result.txHash}'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        setState(() {
          _error = result.error;
        });
      }
    } catch (e) {
      _log.e('Withdrawal failed', error: e);
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  Widget _buildCircuitStatusCard() {
    if (_isExtractingCircuits) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Use indeterminate progress since we don't get intermediate updates from FFI
            const LinearProgressIndicator(
              backgroundColor: Color(0x1AFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      );
    }

    if (_circuitStatus.isAvailable) {
      final batchSize = _circuitStatus.numLeafProofs ?? 16;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Circuit files ready',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade200,
                    ),
                  ),
                  Text(
                    'Batch size: $batchSize proofs${_circuitStatus.totalSizeBytes != null ? ' • ${CircuitManager.formatBytes(_circuitStatus.totalSizeBytes!)}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Circuit files not available - show extract prompt
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_zip, color: Colors.amber.shade400, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Circuit files required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade200,
                      ),
                    ),
                    Text(
                      'Extract bundled files (~163MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _extractCircuits,
              icon: const Icon(Icons.unarchive, size: 18),
              label: const Text('Extract Circuit Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferTrackingCard() {
    if (!_hasLoadedTransfers) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading transfer data...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_trackedTransfers.isNotEmpty) {
      final totalTracked = _trackedTransfers.fold<BigInt>(
        BigInt.zero,
        (sum, t) => sum + t.amount,
      );
      final formattedTotal = NumberFormattingService().formatBalance(
        totalTracked,
        addSymbol: true,
      );

      // Calculate dummy proofs needed
      final batchSize = _circuitStatus.numLeafProofs ?? 16;
      final realProofs = _trackedTransfers.length;
      final dummyProofs = batchSize - (realProofs % batchSize);
      final effectiveDummies = dummyProofs == batchSize ? 0 : dummyProofs;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_trackedTransfers.length} transfer(s) tracked',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade200,
                    ),
                  ),
                  Text(
                    'Total: $formattedTotal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade300,
                    ),
                  ),
                  Text(
                    '$realProofs real + $effectiveDummies dummy = $batchSize proofs per batch',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No tracked transfers - show warning
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No tracked transfers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade200,
                  ),
                ),
                Text(
                  'Mining rewards are only tracked while the app is open. Withdrawal may fail.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormattingService().formatBalance(
      widget.availableBalance,
      addSymbol: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Withdraw Rewards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isWithdrawing ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Available balance card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.2),
                        const Color(0xFF059669).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedBalance,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Circuit status card
                _buildCircuitStatusCard(),
                const SizedBox(height: 16),

                // Transfer tracking status card
                _buildTransferTrackingCard(),
                const SizedBox(height: 32),

                // Destination address
                Text(
                  'Destination Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _destinationController,
                  enabled: !_isWithdrawing,
                  validator: _validateDestination,
                  style: const TextStyle(fontFamily: 'Fira Code', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter destination address',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: _isWithdrawing
                          ? null
                          : () async {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              if (data?.text != null) {
                                _destinationController.text = data!.text!
                                    .trim();
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Amount
                Row(
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Checkbox(
                          value: _withdrawAll,
                          onChanged: _isWithdrawing
                              ? null
                              : (value) {
                                  setState(() {
                                    _withdrawAll = value ?? true;
                                    if (_withdrawAll) {
                                      _updateAmountToMax();
                                    }
                                  });
                                },
                        ),
                        Text(
                          'Withdraw all',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  enabled: !_isWithdrawing && !_withdrawAll,
                  validator: _validateAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    suffixText: 'QTN',
                  ),
                ),
                const SizedBox(height: 16),

                // Fee info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Network fee: 0.1% of withdrawal amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Progress indicator
                if (_isWithdrawing) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Withdraw button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (_isWithdrawing ||
                            _isExtractingCircuits ||
                            !_circuitStatus.isAvailable)
                        ? null
                        : _startWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isWithdrawing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Withdraw',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
