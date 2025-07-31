import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/main/screens/navbar.dart';
import 'package:resonance_network_wallet/models/wallet_state_manager.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

enum SendOverlayState { confirm, progress, complete }

class SendConfirmationOverlay extends StatefulWidget {
  final BigInt amount;
  final String recipientName;
  final String recipientAddress;
  final VoidCallback onClose;
  final BigInt fee;
  final int reversibleTimeSeconds;

  const SendConfirmationOverlay({
    required this.amount,
    required this.recipientName,
    required this.recipientAddress,
    required this.onClose,
    required this.fee,
    required this.reversibleTimeSeconds,
    super.key,
  });

  @override
  SendConfirmationOverlayState createState() => SendConfirmationOverlayState();
}

class SendConfirmationOverlayState extends State<SendConfirmationOverlay> {
  SendOverlayState currentState = SendOverlayState.confirm;
  String? _errorMessage;
  bool _isSending = false;

  void goHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Navbar()),
      (route) => false,
    );
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
      currentState = SendOverlayState.progress;
      _errorMessage = null;
    });

    try {
      final account = await _settingsService.getActiveAccount();

      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      final walletStateManager = Provider.of<WalletStateManager>(
        // ignore: use_build_context_synchronously
        context,
        listen: false,
      );

      debugPrint('Attempting balance transfer...');
      debugPrint('  Recipient: ${widget.recipientAddress}');
      debugPrint('  Amount (BigInt): ${widget.amount}');
      debugPrint('  Fee: ${widget.fee}');
      debugPrint('  Reversible time: ${widget.reversibleTimeSeconds}');

      if (widget.reversibleTimeSeconds <= 0) {
        await walletStateManager.balanceTransfer(
          account,
          widget.recipientAddress,
          widget.amount,
          widget.fee,
        );
      } else {
        await walletStateManager.scheduleReversibleTransferWithDelaySeconds(
          account: account,
          recipientAddress: widget.recipientAddress,
          amount: widget.amount,
          delaySeconds: widget.reversibleTimeSeconds,
          feeEstimate: widget.fee,
        );
      }

      debugPrint('Balance transfer successful.');
      RecentAddressesService().addAddress(widget.recipientAddress);

      if (mounted) {
        setState(() {
          currentState = SendOverlayState.complete;
          _isSending = false;
        });
      }
    } catch (e) {
      debugPrint('Balance transfer failed: $e');
      if (mounted) {
        setState(() {
          currentState = SendOverlayState.confirm;
          _errorMessage = 'Transfer failed: ${e.toString()}';
          _isSending = false;
        });
      }
    }
  }

  Widget _buildConfirmState(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

    final formattedAmount = _formattingService.formatBalance(widget.amount);
    final formattedFee = _formattingService.formatBalance(widget.fee);

    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: widget.onClose,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Send icon and title
          Column(
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/send_icon_1.svg',
                  width: isTablet ? 91 : 51,
                  height: isTablet ? 82 : 42,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'SEND',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 50 : 30,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Transaction details
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Amount with token icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isTablet ? 40 : 25,
                    height: isTablet ? 40 : 25,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFE6E6E6),
                      shape: OvalBorder(),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/res_icon.svg',
                        width: isTablet ? 26 : 11,
                        height: isTablet ? 34 : 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formattedAmount,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 40 : 24,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' ${AppConstants.tokenSymbol}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 12,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 21),

              // Recipient information
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'To:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 22 : 14,
                      fontFamily: 'Fira Code',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTablet
                        ? widget.recipientAddress
                        : AddressFormattingService.formatAddress(
                            widget.recipientAddress,
                          ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 12,
                      fontFamily: 'Fira Code',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: isTablet ? null : 274,
                    child: Text(
                      widget.recipientName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF16CECE),
                        fontSize: isTablet ? 22 : 14,
                        fontFamily: 'Fira Code',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 21),

              // Reversible time information
              if (_isReversible)
                Container(
                  width: isTablet ? 510 : 305,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF313131),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: isTablet ? null : 299,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Reversible for: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 22 : 14,
                                  fontFamily: 'Fira Code',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: _formatReversibleTime(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 12,
                                  fontFamily: 'Fira Code',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // Error message
          if (_errorMessage != null)
            SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: isTablet ? 20 : 12,
                      fontFamily: 'Fira Code',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Network fee and confirm button
          SizedBox(
            width: isTablet ? 510 : 305,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Network fee',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 12,
                        fontFamily: 'Fira Code',
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          '$formattedFee ${AppConstants.tokenSymbol}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 12,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/settings_icon.svg',
                          width: isTablet ? 20 : 14,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: _isSending ? null : _confirmSend,
                  child: Opacity(
                    opacity: _isSending ? 0.5 : 1.0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF0E0E0E),
                          fontSize: isTablet ? 26 : 18,
                          fontFamily: 'Fira Code',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressState(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: goHome,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 91),
          Column(
            spacing: 18,
            children: [
              SizedBox(
                width: isTablet ? 105 : 85,
                height: isTablet ? 105 : 85,
                child: SvgPicture.asset('assets/res_icon.svg'),
              ),
              Text(
                'TRANSACTION \nIN PROGRESS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 42 : 30,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteState(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

    final formattedAmount = _formattingService.formatBalance(widget.amount);

    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: goHome,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sent icon and title
          Column(
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/send_icon_1.svg',
                  width: isTablet ? 91 : 51,
                  height: isTablet ? 82 : 42,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'SENDING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 50 : 30,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Transaction details
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Amount
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isTablet ? 40 : 25,
                    height: isTablet ? 40 : 25,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFE6E6E6),
                      shape: OvalBorder(),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/res_icon.svg',
                        width: isTablet ? 26 : 11,
                        height: isTablet ? 34 : 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formattedAmount,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 40 : 24,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' ${AppConstants.tokenSymbol}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 12,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Recipient information
              Text(
                'will be sent to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.useOpacity(0.5),
                  fontSize: isTablet ? 20 : 12,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isTablet
                        ? widget.recipientAddress
                        : AddressFormattingService.formatAddress(
                            widget.recipientAddress,
                          ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 12,
                      fontFamily: 'Fira Code',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: isTablet ? null : 274,
                    child: Text(
                      widget.recipientName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF16CECE),
                        fontSize: isTablet ? 22 : 14,
                        fontFamily: 'Fira Code',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reversible time information
              if (_isReversible)
                Container(
                  width: isTablet ? 510 : 305,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF313131),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: isTablet ? null : 299,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Reversible for: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 22 : 14,
                                  fontFamily: 'Fira Code',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: _formatReversibleTime(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 12,
                                  fontFamily: 'Fira Code',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 46),

          // Done Button
          GestureDetector(
            onTap: goHome,
            child: Container(
              width: isTablet ? 510 : 305,
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF0E0E0E),
                  fontSize: isTablet ? 26 : 18,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (currentState) {
      case SendOverlayState.confirm:
        content = _buildConfirmState(context);
        break;
      case SendOverlayState.progress:
        content = _buildProgressState(context);
        break;
      case SendOverlayState.complete:
        content = _buildCompleteState(context);
        break;
    }

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
              height:
                  MediaQuery.of(context).size.height *
                  AppConstants.sendingSheetHeightFraction,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
              decoration: ShapeDecoration(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
