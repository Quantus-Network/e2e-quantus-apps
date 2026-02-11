import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/components/back_button.dart';
import 'package:resonance_network_wallet/v2/components/gradient_background.dart';
import 'package:resonance_network_wallet/v2/components/success_check.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class DepositScreen extends StatefulWidget {
  final SwapOrder order;
  const DepositScreen({super.key, required this.order});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _swapService = SwapService();
  late SwapOrder _order;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _confirmSent() async {
    setState(() => _confirming = true);
    try {
      final updated = await _swapService.confirmFundsSent(_order.orderId);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _confirming = false;
      });
      _pollStatus();
    } catch (e) {
      setState(() => _confirming = false);
    }
  }

  Future<void> _pollStatus() async {
    while (mounted && _order.status == SwapStatus.processing) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      try {
        final updated = await _swapService.getSwapStatus(_order.orderId);
        if (!mounted) return;
        setState(() => _order = updated);
      } catch (_) {}
    }
  }

  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: _order.depositAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    final quote = _order.quote;
    final usd = quote.fromAmount * _swapService.getUsdPrice(quote.fromToken);

    return Scaffold(
      backgroundColor: colors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _header(colors, text),
                const SizedBox(height: 40),
                if (_order.status == SwapStatus.complete)
                  _completedBody(colors, text)
                else if (_order.status == SwapStatus.processing)
                  _processingBody(colors, text)
                else
                  _depositBody(colors, text, quote, usd),
                const Spacer(),
                if (_order.status == SwapStatus.depositing) _sentButton(colors, text),
                if (_order.status == SwapStatus.complete) _doneButton(colors, text),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppColorsV2 colors, AppTextTheme text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const AppBackButton(),
        Text('Swap', style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20)),
        Icon(Icons.info_outline, color: colors.textPrimary, size: 24),
      ],
    );
  }

  Widget _depositBody(AppColorsV2 colors, AppTextTheme text, SwapQuote quote, double usd) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Deposit Amount', style: text.detail?.copyWith(color: colors.textSecondary)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: quote.totalAmount.toStringAsFixed(2)));
              },
              child: Icon(Icons.copy, color: colors.textTertiary, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: colors.accentPink.withValues(alpha: 0.3), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(quote.totalAmount.toStringAsFixed(2), style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 24)),
          ],
        ),
        Text('\$${usd.toStringAsFixed(2)}', style: text.detail?.copyWith(color: colors.textTertiary)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: QrImageView(data: _order.depositAddress, version: QrVersions.auto, size: 180),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _copyAddress,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _order.depositAddress,
                  style: text.detail?.copyWith(color: colors.textSecondary, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.copy, color: colors.textTertiary, size: 12),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _actionBtn(Icons.copy, 'Copy', _copyAddress, colors, text)),
            const SizedBox(width: 16),
            Expanded(child: _actionBtn(Icons.qr_code, 'Share QR', () {}, colors, text)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Use your ${quote.fromToken.symbol} or ${quote.fromToken.network} wallet to deposit funds. Depositing other assets may result in loss of funds.',
          style: text.detail?.copyWith(color: colors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.textPrimary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _processingBody(AppColorsV2 colors, AppTextTheme text) {
    return Column(
      children: [
        const SizedBox(height: 80),
        CircularProgressIndicator(color: colors.accentGreen),
        const SizedBox(height: 32),
        Text('Processing Swap', style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20)),
        const SizedBox(height: 12),
        Text('This may take a few minutes...', style: text.paragraph?.copyWith(color: colors.textSecondary)),
      ],
    );
  }

  Widget _completedBody(AppColorsV2 colors, AppTextTheme text) {
    return Column(
      children: [
        const SizedBox(height: 80),
        const SuccessCheck(),
        const SizedBox(height: 32),
        Text('Swap Complete', style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20)),
        const SizedBox(height: 12),
        Text(
          '${_order.quote.toAmount.toStringAsFixed(2)} QUAN has been added to your wallet',
          style: text.paragraph?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _sentButton(AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: _confirming ? null : _confirmSent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
        ),
        child: Center(
          child: _confirming
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: colors.textPrimary, strokeWidth: 2))
              : Text("I've sent the funds", style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _doneButton(AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
        ),
        child: Center(
          child: Text('Done', style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
