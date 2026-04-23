import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/currency_display_provider.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/send/review_send_screen.dart';
import 'package:resonance_network_wallet/v2/screens/send/send_providers.dart';
import 'package:resonance_network_wallet/v2/screens/send/send_screen_logic.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class InputAmountScreen extends ConsumerStatefulWidget {
  final String recipientAddress;
  final String? recipientChecksum;
  final String? initialAmount;
  final bool isPayMode;

  const InputAmountScreen({
    super.key,
    required this.recipientAddress,
    this.recipientChecksum,
    this.initialAmount,
    this.isPayMode = false,
  });

  @override
  ConsumerState<InputAmountScreen> createState() => _InputAmountScreenState();
}

class _InputAmountScreenState extends ConsumerState<InputAmountScreen> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  final _fmt = NumberFormattingService();
  final _checksumService = HumanReadableChecksumService();

  String? _recipientChecksum;
  BigInt _amount = BigInt.zero;
  BigInt _networkFee = BigInt.zero;
  int _blockHeight = 0;
  bool _isFetchingFee = false;

  @override
  void initState() {
    super.initState();
    assert(widget.recipientAddress.trim().isNotEmpty, 'InputAmountScreen requires a recipient');
    _amountController.addListener(_onAmountChanged);
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }
    if (widget.recipientChecksum != null) {
      _recipientChecksum = widget.recipientChecksum;
    } else {
      _checksumService.getHumanReadableName(widget.recipientAddress.trim()).then((name) {
        if (mounted) setState(() => _recipientChecksum = name);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEstimatedFee();
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final parsed = _fmt.parseAmount(_amountController.text);
    setState(() => _amount = parsed ?? BigInt.zero);
    if (_amount > BigInt.zero) _fetchFee();
  }

  Future<void> _fetchEstimatedFee() async {
    final displayAccount = ref.read(activeAccountProvider).value;
    if (displayAccount is! RegularAccount) return;
    final account = displayAccount.account;
    try {
      final balancesService = ref.read(balancesServiceProvider);
      final feeData = await balancesService.getBalanceTransferFee(
        account,
        account.accountId,
        _fmt.parseAmount('1000') ?? BigInt.zero,
      );
      if (!mounted) return;
      setState(() {
        _networkFee = feeData.fee;
        _blockHeight = feeData.blockNumber;
      });
    } catch (e) {
      debugPrint('Estimated fee fetch error: $e');
    }
  }

  Future<void> _fetchFee() async {
    if (_isFetchingFee) return;
    setState(() => _isFetchingFee = true);
    try {
      final displayAccount = ref.read(activeAccountProvider).value;
      if (displayAccount is! RegularAccount) return;
      final balancesService = ref.read(balancesServiceProvider);
      final feeData = await balancesService.getBalanceTransferFee(
        displayAccount.account,
        widget.recipientAddress.trim(),
        _amount,
      );
      if (!mounted) return;
      setState(() {
        _networkFee = feeData.fee;
        _blockHeight = feeData.blockNumber;
      });
    } catch (e) {
      debugPrint('Fee fetch error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingFee = false);
    }
  }

  void _setMax() {
    final balance = ref.read(effectiveMaxBalanceProvider).value ?? BigInt.zero;
    final max = SendScreenLogic.calculateMaxSendableAmount(balance: balance, networkFee: _networkFee);
    _amountController.text = _fmt.formatBalance(max, maxDecimals: AppConstants.decimals, addThousandsSeparators: false);
  }

  Future<void> _openReview() async {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSendScreen(
          recipientAddress: widget.recipientAddress,
          amount: _amount,
          networkFee: _networkFee,
          blockHeight: _blockHeight,
          recipientChecksum: _recipientChecksum!,
          isPayMode: widget.isPayMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeAccountProvider);
    final colors = context.colors;
    final text = context.themeText;
    final balance = ref.watch(effectiveMaxBalanceProvider);
    final activeId = ref.watch(activeAccountProvider).value?.account.accountId ?? '';
    final recipient = widget.recipientAddress.trim();

    final amountStatus = SendScreenLogic.getAmountStatus(_amount, balance.value ?? BigInt.zero, _networkFee);
    final btnDisabled =
        _recipientChecksum == null ||
        SendScreenLogic.isButtonDisabled(
          hasAddressError: false,
          amountStatus: amountStatus,
          recipientText: recipient,
          activeAccountId: activeId,
        );
    final btnText = SendScreenLogic.getButtonText(
      hasAddressError: false,
      amountStatus: amountStatus,
      recipientText: recipient,
      amount: _amount,
      activeAccountId: activeId,
      formattingService: _fmt,
    );

    return ScaffoldBase(
      appBar: V2AppBar(title: widget.isPayMode ? 'Pay' : 'Send'),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _recipientCard(colors, text),
          Expanded(child: _amountCenter(colors, text)),
          _bottomSection(colors, text, btnText, balance, btnDisabled),
        ],
      ),
    );
  }

  Widget _recipientCard(AppColorsV2 colors, AppTextTheme text) {
    final addr = widget.recipientAddress.trim();
    final shortAddr = AddressFormattingService.formatAddress(addr);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: colors.surfaceDeep,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderButton),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEND TO',
                  style: TextStyle(
                    fontFamily: AppTextTheme.fontFamilySecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.85,
                    color: colors.textLabel,
                  ),
                ),
                const SizedBox(height: 16),
                if (_recipientChecksum != null) ...[
                  Text(
                    _recipientChecksum!,
                    style: text.smallParagraph?.copyWith(color: colors.checksum, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  shortAddr,
                  style: text.detail?.copyWith(
                    color: colors.textMuted,
                    fontFamily: AppTextTheme.fontFamilySecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: colors.background,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(true),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderButton),
                ),
                child: Icon(Icons.edit_outlined, size: 18, color: colors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCenter(AppColorsV2 colors, AppTextTheme text) {
    final display = ref.watch(txAmountDisplayProvider)(_amount, withSignPrefix: false, withQuanSymbol: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [DecimalInputFilter()],
                    style: text.transactionDetailAmountPrimary?.copyWith(
                      color: _amount == BigInt.zero ? colors.textTertiary : colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0',
                      hintStyle: text.transactionDetailAmountPrimary?.copyWith(color: colors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppConstants.tokenSymbol,
                  style: text.transactionDetailAmountSymbol?.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '≈ ${display.secondaryAmount}',
            style: text.paragraph?.copyWith(color: colors.textTertiary, fontFamily: AppTextTheme.fontFamilySecondary),
          ),
        ],
      ),
    );
  }

  Widget _bottomSection(
    AppColorsV2 colors,
    AppTextTheme text,
    String btnText,
    AsyncValue<BigInt> balance,
    bool btnDisabled,
  ) {
    return Container(
      padding: const EdgeInsets.only(top: 25, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Balance:', style: text.smallParagraph?.copyWith(color: colors.textTertiary)),
                    const SizedBox(height: 4),
                    balance.when(
                      data: (b) => Text(
                        '${_fmt.formatBalance(b)} ${AppConstants.tokenSymbol}',
                        style: text.smallParagraph?.copyWith(color: colors.textTertiary),
                      ),
                      loading: () => Text('...', style: text.smallParagraph?.copyWith(color: colors.textTertiary)),
                      error: (_, _) => Text('—', style: text.smallParagraph?.copyWith(color: colors.textTertiary)),
                    ),
                  ],
                ),
              ),
              IntrinsicWidth(
                child: QuantusButton.simple(
                  label: 'Max',
                  onTap: _setMax,
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  variant: ButtonVariant.transparent,
                  textStyle: text.smallParagraph?.copyWith(
                    color: colors.accentOrange,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          QuantusButton.simple(
            label: btnText,
            variant: ButtonVariant.primary,
            isDisabled: btnDisabled,
            onTap: _openReview,
          ),
        ],
      ),
    );
  }
}
