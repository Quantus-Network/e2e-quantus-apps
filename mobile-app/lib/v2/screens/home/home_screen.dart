import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/dotted_border.dart';
import 'package:resonance_network_wallet/features/components/shared_address_action_sheet.dart';
import 'package:resonance_network_wallet/features/components/skeleton.dart';
import 'package:resonance_network_wallet/providers/remote_config_provider.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/quantus_icon_button.dart';
import 'package:resonance_network_wallet/v2/screens/accounts/accounts_sheet.dart';
import 'package:resonance_network_wallet/v2/screens/receive/receive_sheet.dart';
import 'package:resonance_network_wallet/v2/screens/send/send_sheet.dart';
import 'package:resonance_network_wallet/v2/screens/settings/settings_screen.dart';
import 'package:resonance_network_wallet/v2/screens/pos/pos_amount_screen.dart';
import 'package:resonance_network_wallet/v2/screens/swap/swap_screen.dart';
import 'package:resonance_network_wallet/providers/account_id_list_cache.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/active_account_transactions_provider.dart';
import 'package:resonance_network_wallet/providers/filtered_all_transactions_provider.dart';
import 'package:resonance_network_wallet/providers/route_intent_providers.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';
import 'package:resonance_network_wallet/v2/screens/home/activity_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final NumberFormattingService _fmt = NumberFormattingService();

  Future<void> _refresh() async {
    final active = ref.read(activeAccountProvider).value;
    ref.invalidate(balanceProviderFamily);
    ref.invalidate(balanceProviderRaw);
    ref.invalidate(activeAccountTransactionsProvider);
    if (active != null) {
      await ref
          .read(filteredPaginationControllerProviderFamily(AccountIdListCache.get([active.account.accountId])).notifier)
          .loadingRefresh();
    }
  }

  void _processIntentIfAvailable() {
    final payment = ref.read(paymentIntentProvider);
    if (payment != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(paymentIntentProvider.notifier).state = null;
        showSendSheetV2(context, address: payment.to, amount: payment.amount, isPayMode: true);
      });
      return;
    }

    final shared = ref.read(sharedAccountIntentProvider);
    if (shared != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sharedAccountIntentProvider.notifier).state = null;
        showSharedAddressActionSheet(context, shared);
      });
    }
  }

  Future<void> toggleBalanceHidden(bool isBalanceHidden) async {
    final isBalanceHiddenNotifier = ref.read(isBalanceHiddenProvider.notifier);
    await isBalanceHiddenNotifier.setIsBalanceHidden(!isBalanceHidden);
  }

  @override
  Widget build(BuildContext context) {
    _processIntentIfAvailable();

    final isBalanceHidden = ref.watch(isBalanceHiddenProvider);
    final isPosMode = ref.watch(posModeProvider);
    final accountAsync = ref.watch(activeAccountProvider);
    final balanceAsync = ref.watch(balanceProvider);
    final txAsync = ref.watch(activeAccountTransactionsProvider);
    final colors = context.colors;
    final text = context.themeText;

    Widget screen = accountAsync.when(
      loading: () => ScaffoldBase(
        child: Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      ),
      error: (e, _) => ScaffoldBase(
        child: Center(
          child: Text('Error: $e', style: text.detail?.copyWith(color: colors.textError)),
        ),
      ),
      data: (active) {
        if (active == null) {
          return const ScaffoldBase(child: Center(child: Text('No active account')));
        }
        return ScaffoldBase.refreshable(
          onRefresh: _refresh,
          slivers: [
            _buildContent(active, balanceAsync, isBalanceHidden, colors, text),
            ActivitySection(txAsync: txAsync, activeAccount: active.account, onRetry: _refresh),
            SizedBox(height: isPosMode ? 120 : 58),
          ],
        );
      },
    );

    if (!isPosMode) return screen;

    return Stack(
      children: [
        screen,
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: _buildPosButton(colors, text),
        ),
      ],
    );
  }

  Widget _buildPosButton(AppColorsV2 colors, AppTextTheme text) {
    return QuantusButton.simple(
      label: 'New Charge',
      variant: ButtonVariant.success,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosAmountScreen())),
      textStyle: text.smallTitle?.copyWith(fontWeight: FontWeight.w700, fontSize: 20, decoration: TextDecoration.none),
    );
  }

  Widget _buildContent(
    DisplayAccount active,
    AsyncValue<BigInt> balanceAsync,
    bool isBalanceHidden,
    AppColorsV2 colors,
    AppTextTheme text,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildTopBar(active, isBalanceHidden, colors),
        const SizedBox(height: 40),
        _buildBalance(balanceAsync, isBalanceHidden, colors, text),
        const SizedBox(height: 40),
        if (active is RegularAccount) ...[_buildActionButtons(), const SizedBox(height: 40)],
        DottedBorder(
          dashLength: 10,
          gapLength: 6,
          color: colors.borderButton.useOpacity(0.5),
          child: const SizedBox(width: double.infinity, height: 1),
        ),
      ],
    );
  }

  Widget _buildTopBar(DisplayAccount active, bool isBalanceHidden, AppColorsV2 colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => showAccountsSheet(context),
          child: SvgPicture.asset('assets/v2/uppercase_q.svg', width: 32, height: 32),
        ),
        Row(
          children: [
            _circleIconButton(
              icon: isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              colors: colors,
              onTap: () => toggleBalanceHidden(isBalanceHidden),
              isActive: isBalanceHidden,
            ),
            const SizedBox(width: 12),
            _circleIconButton(
              icon: Icons.settings_outlined,
              colors: colors,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreenV2())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required AppColorsV2 colors,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return QuantusIconButton.circular(icon: icon, onTap: onTap, isActive: isActive);
  }

  Widget _buildBalance(AsyncValue<BigInt> balanceAsync, bool isBalanceHidden, AppColorsV2 colors, AppTextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        balanceAsync.when(
          data: (balance) {
            final formatted = isBalanceHidden ? '- - - - -' : _fmt.formatBalance(balance, addSymbol: true);
            final usdFormatted = isBalanceHidden ? '- - - - -' : '\$${_fmt.formatBalance(balance)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatted, style: text.extraLargeTitle?.copyWith(color: colors.textPrimary)),
                const SizedBox(height: 6),
                Text('≈ $usdFormatted', style: text.paragraph?.copyWith(color: colors.textSecondary)),
              ],
            );
          },
          loading: () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Skeleton(width: 200, height: 36),
              Text(' ${AppConstants.tokenSymbol}', style: text.smallTitle?.copyWith(color: colors.textPrimary)),
            ],
          ),
          error: (_, _) => Text('Error loading balance', style: text.detail?.copyWith(color: colors.textError)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final enableSwap = ref.watch(remoteConfigProvider).enableSwap;

    final receiveCard = _actionCard(
      iconAsset: 'assets/v2/action_receive.svg',
      label: 'Receive',
      onTap: () => showReceiveSheetV2(context),
    );

    final sendCard = _actionCard(
      iconAsset: 'assets/v2/action_send.svg',
      label: 'Send',
      onTap: () => showSendSheetV2(context),
    );

    if (!enableSwap) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 151, child: receiveCard),
          const SizedBox(width: 20),
          SizedBox(width: 151, child: sendCard),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: receiveCard),
        const SizedBox(width: 15),
        Expanded(child: sendCard),
        const SizedBox(width: 15),
        Expanded(
          child: _actionCard(
            iconAsset: 'assets/v2/action_swap.svg',
            label: 'Swap',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapScreen())),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({required String iconAsset, required String label, required VoidCallback onTap}) {
    return QuantusButton.simple(
      label: label,
      onTap: onTap,
      icon: SvgPicture.asset(iconAsset, width: 24, height: 24),
      iconPlacement: IconPlacement.top,
      padding: const EdgeInsets.all(14),
      variant: ButtonVariant.secondary,
      textStyle: context.themeText.paragraph?.copyWith(color: context.colors.textPrimary.useOpacity(0.8)),
    );
  }
}
