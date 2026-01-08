// ignore_for_file: unused_import

import 'dart:typed_data';
import 'dart:ui';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/generated/schrodinger/types/qp_scheduler/block_number_or_timestamp.dart' as qp;
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/main/screens/navbar.dart';
import 'package:resonance_network_wallet/features/main/screens/send/steps/hardware_scan_step.dart';
import 'package:resonance_network_wallet/features/main/screens/send/steps/hardware_sign_step.dart';
import 'package:resonance_network_wallet/features/main/screens/send/steps/send_complete_step.dart';
import 'package:resonance_network_wallet/features/main/screens/send/steps/send_confirm_step.dart';
import 'package:resonance_network_wallet/features/main/screens/send/steps/send_progress_step.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/providers/pending_transactions_provider.dart';
import 'package:resonance_network_wallet/services/hardware_wallet_service.dart';
import 'package:resonance_network_wallet/services/telemetry_service.dart';
import 'package:resonance_network_wallet/services/transaction_submission_service.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

enum SendOverlayState { confirm, progress, complete, hardwareSign, hardwareScan }

class SendConfirmationOverlay extends ConsumerStatefulWidget {
  final BigInt amount;
  final String recipientName;
  final String recipientAddress;
  final VoidCallback onClose;
  final BigInt fee;
  final int reversibleTimeSeconds;
  final int blockHeight;

  const SendConfirmationOverlay({
    required this.amount,
    required this.recipientName,
    required this.recipientAddress,
    required this.onClose,
    required this.fee,
    required this.reversibleTimeSeconds,
    required this.blockHeight,
    super.key,
  });

  @override
  SendConfirmationOverlayState createState() => SendConfirmationOverlayState();
}

class SendConfirmationOverlayState extends ConsumerState<SendConfirmationOverlay> {
  SendOverlayState currentState = SendOverlayState.confirm;
  String? _errorMessage;
  bool _isSending = false;
  Account? _hardwareAccount;
  UnsignedTransactionData? _hardwareUnsignedData;
  bool _isHardwareSubmitting = false;

  void goHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Navbar()), (route) => false);
  }

  void _handleDismiss() {
    switch (currentState) {
      case SendOverlayState.confirm:
        widget.onClose();
        break;
      case SendOverlayState.progress:
        // do nothing
        break;
      case SendOverlayState.complete:
        goHome();
        break;
      case SendOverlayState.hardwareSign:
      case SendOverlayState.hardwareScan:
        widget.onClose();
        break;
    }
  }

  bool get _isReversible => widget.reversibleTimeSeconds > 0;

  final NumberFormattingService _formattingService = NumberFormattingService();
  final SettingsService _settingsService = SettingsService();

  String _formatReversibleTime() {
    final days = widget.reversibleTimeSeconds ~/ 86400;
    final hours = (widget.reversibleTimeSeconds % 86400) ~/ 3600;
    final minutes = (widget.reversibleTimeSeconds % 3600) ~/ 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}, '
          '$hours hr${hours != 1 ? 's' : ''}, '
          '$minutes min${minutes != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hr${hours != 1 ? 's' : ''}, '
          '$minutes min${minutes != 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  Future<void> _confirmSend() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final account = (await _settingsService.getActiveAccount())!;

      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      RecentAddressesService().addAddress(widget.recipientAddress);

      if (account.accountType == AccountType.keystone || AppConstants.debugHardwareWallet) {
        await _startHardwareFlow(account);
        return;
      } else {
        // For local wallets, show progress state
        setState(() {
          currentState = SendOverlayState.progress;
        });
        await _handleLocalWalletTransaction(account);

        if (mounted) {
          setState(() {
            currentState = SendOverlayState.complete;
            _isSending = false;
          });
        }
      }
    } catch (e) {
      print('Balance transfer failed: $e');
      if (mounted) {
        setState(() {
          currentState = SendOverlayState.confirm;
          _errorMessage = 'Transfer failed: ${e.toString()}';
          _isSending = false;
        });
      }
    }
  }

  RuntimeCall _buildRuntimeCall() {
    final balancesService = BalancesService();
    final reversibleTransfersService = ReversibleTransfersService();

    if (widget.reversibleTimeSeconds <= 0) {
      return balancesService.getBalanceTransferCall(widget.recipientAddress, widget.amount);
    }

    final delay = qp.Timestamp(BigInt.from(widget.reversibleTimeSeconds) * BigInt.from(1000));
    return reversibleTransfersService.getReversibleTransferCall(widget.recipientAddress, widget.amount, delay);
  }

  Future<void> _startHardwareFlow(Account account) async {
    setState(() {
      currentState = SendOverlayState.hardwareSign;
      _hardwareAccount = account;
      _hardwareUnsignedData = null;
      _isHardwareSubmitting = false;
    });

    final substrateService = SubstrateService();
    final unsignedData = await substrateService.getUnsignedTransactionPayload(account, _buildRuntimeCall());
    if (!mounted) return;

    setState(() {
      _hardwareUnsignedData = unsignedData;
      _isSending = false;
    });
  }

  void _goToHardwareScanStep() {
    setState(() {
      currentState = SendOverlayState.hardwareScan;
      _isHardwareSubmitting = false;
    });
  }

  Future<void> _onHardwareSignatureScanned(List<String> signatureQRParts) async {
    if (_isHardwareSubmitting) return;
    final unsignedData = _hardwareUnsignedData;
    final account = _hardwareAccount;
    if (unsignedData == null || account == null) return;

    setState(() {
      _isHardwareSubmitting = true;
    });

    await _processHardwareSignature(signatureQRParts, unsignedData, account);
  }

  // Simulate by generating a signature locally - allows us to test the signature flow without a hardware wallet
  // we just pretend one of our wallets is a hardware wallet.. 
  Future<void> _simulateHardwareSignature() async {
    final unsignedData = _hardwareUnsignedData;
    final account = _hardwareAccount;
    if (unsignedData == null || account == null) return;

    try {
      final hwService = ref.read(hardwareWalletServiceProvider);
      final signatureWithPublicKey = await hwService.simulateSignature(account, unsignedData);

      final ur = hwService.encodePayloadAsUr(signatureWithPublicKey);
      await _onHardwareSignatureScanned([ur]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Simulation failed: $e';
        _isHardwareSubmitting = false;
      });
    }
  }

  Future<void> _handleLocalWalletTransaction(Account account) async {
    final submissionService = ref.read(transactionSubmissionServiceProvider);

    debugPrint('Attempting balance transfer...');
    debugPrint('  Recipient: ${widget.recipientAddress}');
    debugPrint('  Amount (BigInt): ${widget.amount}');
    debugPrint('  Fee: ${widget.fee}');
    debugPrint('  Reversible time: ${widget.reversibleTimeSeconds}');

    if (widget.reversibleTimeSeconds <= 0) {
      await submissionService.balanceTransfer(
        account,
        widget.recipientAddress,
        widget.amount,
        widget.fee,
        widget.blockHeight,
      );
    } else {
      await submissionService.scheduleReversibleTransferWithDelaySeconds(
        account: account,
        recipientAddress: widget.recipientAddress,
        amount: widget.amount,
        delaySeconds: widget.reversibleTimeSeconds,
        feeEstimate: widget.fee,
        blockHeight: widget.blockHeight,
      );
    }
  }

  Future<void> _processHardwareSignature(
    List<String> signatureQRParts,
    UnsignedTransactionData unsignedData,
    Account account,
  ) async {
    try {
      final hwService = ref.read(hardwareWalletServiceProvider);

      // 1. Decode UR
      final signatureBytes = hwService.decodeSignatureUr(signatureQRParts);

      // 2. Parse & Validate
      final (:signature, :publicKey) = hwService.parseSignatureBytes(signatureBytes);

      // 3. Submit
      final substrateService = SubstrateService();
      final submissionService = ref.read(transactionSubmissionServiceProvider);
      final pendingTx = PendingTransactionEvent(
        tempId: 'pending_${DateTime.now().millisecondsSinceEpoch}',
        from: account.accountId,
        to: widget.recipientAddress,
        amount: widget.amount,
        timestamp: DateTime.now(),
        transactionState: TransactionState.created,
        fee: widget.fee,
        blockNumber: widget.blockHeight,
      );

      ref.read(pendingTransactionsProvider.notifier).add(pendingTx);

      Future<Uint8List> submissionBuilder() async {
        return await substrateService.submitExtrinsicWithExternalSignature(unsignedData, signature, publicKey);
      }

      TelemetryService().sendEvent('send_transfer_hardware');
      await submissionService.submitAndTrackTransaction(submissionBuilder, pendingTx);

      if (mounted) {
        setState(() {
          currentState = SendOverlayState.complete;
          _isSending = false;
          _isHardwareSubmitting = false;
        });
      }
    } catch (e) {
      print('Hardware signature processing failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Signature processing failed: ${e.toString()}';
          _isHardwareSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (currentState) {
      case SendOverlayState.confirm:
        content = SendConfirmStep(
          amount: widget.amount,
          formattedAmount: _formattingService.formatBalance(widget.amount),
          formattedFee: _formattingService.formatBalance(widget.fee),
          recipientName: widget.recipientName,
          recipientAddress: widget.recipientAddress,
          tokenSymbol: AppConstants.tokenSymbol,
          isReversible: _isReversible,
          formattedReversibleTime: _formatReversibleTime(),
          errorMessage: _errorMessage,
          isSending: _isSending,
          onClose: widget.onClose,
          onConfirm: _confirmSend,
        );
        break;
      case SendOverlayState.progress:
        content = SendProgressStep(onClose: goHome);
        break;
      case SendOverlayState.complete:
        content = SendCompleteStep(
          formattedAmount: _formattingService.formatBalance(widget.amount),
          recipientName: widget.recipientName,
          recipientAddress: widget.recipientAddress,
          tokenSymbol: AppConstants.tokenSymbol,
          isReversible: _isReversible,
          formattedReversibleTime: _formatReversibleTime(),
          onDone: goHome,
        );
        break;
      case SendOverlayState.hardwareSign:
        content = HardwareSignStep(
          unsignedData: _hardwareUnsignedData,
          onClose: widget.onClose,
          onNext: _goToHardwareScanStep,
        );
        break;
      case SendOverlayState.hardwareScan:
        content = HardwareScanStep(
          isSubmitting: _isHardwareSubmitting,
          errorMessage: _errorMessage,
          onClose: widget.onClose,
          onBack: () => setState(() => currentState = SendOverlayState.hardwareSign),
          onSignatureScanned: _onHardwareSignatureScanned,
          showDebugButton: AppConstants.debugHardwareWallet,
          onSimulate: _simulateHardwareSignature,
        );
        break;
    }
    final effectiveSheetHeightFraction = context.isSmallHeight ? 0.9 : AppConstants.sendingSheetHeightFraction;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleDismiss();
      },
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(color: Colors.black.useOpacity(0.3)),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * effectiveSheetHeightFraction,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: ShapeDecoration(
                color: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
