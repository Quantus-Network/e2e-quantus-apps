import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/snackbar_helper.dart';
import 'package:resonance_network_wallet/features/components/transactions_list.dart';
import 'package:resonance_network_wallet/features/main/screens/accounts_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/receive_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/transactions_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/welcome_screen.dart';
import 'package:resonance_network_wallet/models/wallet_state_manager.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class WalletMain extends StatefulWidget {
  const WalletMain({super.key});

  @override
  State<WalletMain> createState() => _WalletMainState();
}

class _WalletMainState extends State<WalletMain> {
  final NumberFormattingService _formattingService = NumberFormattingService();
  final SubstrateService _substrateService = SubstrateService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Access the WalletStateManager from the provider without listening to
    // changes
    final walletStateManager = Provider.of<WalletStateManager>(
      context,
      listen: false,
    );
    // Initial data load
    walletStateManager.load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required Widget iconWidget,
    required String label,
    required Color borderColor,
    required VoidCallback onPressed,
    required bool isTablet,
    bool disabled = false,
  }) {
    final color = disabled ? Colors.white.useOpacity(0.5) : Colors.white;
    final bgColor = Colors.black.useOpacity(166 / 255.0);
    final effectiveBorderColor = disabled
        ? borderColor.useOpacity(0.5)
        : borderColor;

    Widget finalIconWidget = iconWidget;
    if (iconWidget is SvgPicture) {
      finalIconWidget = SvgPicture.asset(
        (iconWidget.bytesLoader as SvgAssetLoader).assetName,
        width: isTablet ? 30 : 20,
        height: isTablet ? 30 : 20,
      );
    } else if (iconWidget is Icon) {
      finalIconWidget = Icon(
        iconWidget.icon,
        color: color,
        size: isTablet ? 30 : 20,
      );
    } else if (iconWidget is Image) {
      finalIconWidget = SizedBox(
        width: isTablet ? 30 : 20,
        height: isTablet ? 30 : 20,
        child: iconWidget,
      );
    }

    return Opacity(
      opacity: disabled ? 0.7 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: isTablet ? 105 : 65,
          height: isTablet ? 96 : 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            color: bgColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: effectiveBorderColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              finalIconWidget,
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: isTablet ? 16 : 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    WalletStateManager walletStateManager,
    bool isTablet,
  ) {
    if (walletStateManager.isTxHistoryLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          color: Colors.black.withAlpha(64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0CE6ED)),
            ),
          ),
        ),
      );
    }

    if (walletStateManager.txHistoryError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: Colors.black.withAlpha(64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                walletStateManager.txHistoryError ?? 'Error',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 18 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: walletStateManager.load,
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: isTablet ? 18 : 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeAccount = walletStateManager.walletData?.account;
    if (activeAccount == null) {
      return const SizedBox.shrink(); // or a placeholder
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
          child: Text(
            'Recent Transactions',
            style: TextStyle(
              color: const Color(0xFFE6E6E6),
              fontSize: isTablet ? 20 : 14,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        RecentTransactionsList(
          transactions: walletStateManager.combinedTransactions
              .take(5)
              .toList(),
          currentWalletAddress: activeAccount.accountId,
        ),
        if (walletStateManager.combinedTransactions.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 18 : 12.0, right: 12.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionsScreen(manager: walletStateManager),
                    ),
                  );
                },
                child: Text(
                  'Transaction History →',
                  style: TextStyle(
                    color: Colors.white.useOpacity(0.80),
                    fontSize: isTablet ? 16 : 12,
                    fontFamily: 'Fira Code',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _logout() async {
    try {
      await _substrateService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        showTopSnackBar(
          context,
          title: 'Error',
          message: 'Logout failed: ${e.toString()}',
          icon: buildErrorIcon(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;
    final walletStateManager = Provider.of<WalletStateManager>(context);

    if (walletStateManager.isWalletLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final hasWalletData = walletStateManager.walletData != null;
    if (walletStateManager.walletError != null || !hasWalletData) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Failed to Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 24 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Could not load wallet data. Please check your network '
                        'connection and try again.',
                        style: TextStyle(
                          color: Colors.white.useOpacity(0.7),
                          fontSize: isTablet ? 20 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFullWidthActionButton(
                    label: 'Retry',
                    onTap: () => walletStateManager.load(),
                    isTablet: isTablet,
                    gradient: const LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0xFF0CE6ED), Color(0xFF8AF9A8)],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildFullWidthActionButton(
                    label: 'Logout',
                    onTap: _logout,
                    isTablet: isTablet,
                    backgroundColor: Colors.white.useOpacity(0.2),
                    textColor: Colors.white.useOpacity(0.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final walletData = walletStateManager.walletData!;
    final activeAccount = walletData.account;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/light_leak_effect_background.jpg'),
            fit: BoxFit.cover,
            opacity: 0.54,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: RefreshIndicator(
              onRefresh: () => walletStateManager.load(),
              color: const Color(0xFF0CE6ED),
              backgroundColor: Colors.black,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset(
                              'assets/quantus_logo_hz.svg',
                              height: isTablet ? 60 : 40,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: SvgPicture.asset(
                                    'assets/wallet_icon.svg',
                                    width: isTablet ? 32 : 24,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AccountsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AccountsScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/active_dot.png',
                                      width: isTablet ? 28 : 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      activeAccount.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 24 : 16,
                                        fontFamily: 'Fira Code',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white70,
                                      size: isTablet ? 18 : 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formattingService.formatBalance(
                                      walletStateManager.estimatedBalance,
                                    ),
                                    style: TextStyle(
                                      color: const Color(0xFFE6E6E6),
                                      fontSize: isTablet ? 52 : 40,
                                      fontFamily: 'Fira Code',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${AppConstants.tokenSymbol}',
                                    style: TextStyle(
                                      color: const Color(0xFFE6E6E6),
                                      fontSize: isTablet ? 28 : 20,
                                      fontFamily: 'Fira Code',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          spacing: isTablet ? 28 : 0,
                          mainAxisAlignment: isTablet
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionButton(
                              iconWidget: SvgPicture.asset(
                                'assets/send_icon_1.svg',
                              ),
                              label: 'SEND',
                              borderColor: const Color(0xFF0AD4F6),
                              onPressed: () {
                                Navigator.pushNamed(context, '/send');
                              },
                              isTablet: isTablet,
                            ),
                            _buildActionButton(
                              iconWidget: SvgPicture.asset(
                                'assets/receive_icon_1.svg',
                              ),
                              label: 'RECEIVE',
                              borderColor: const Color(0xFFB258F1),
                              onPressed: () {
                                showReceiveSheet(context);
                              },
                              isTablet: isTablet,
                            ),
                            _buildActionButton(
                              iconWidget: SvgPicture.asset(
                                'assets/swap_icon_1.svg',
                              ),
                              label: 'SWAP',
                              borderColor: const Color(0xFF0AD4F6),
                              onPressed: () {},
                              isTablet: isTablet,
                              disabled: true,
                            ),
                            _buildActionButton(
                              iconWidget: SvgPicture.asset(
                                'assets/bridge_icon.svg',
                              ),
                              label: 'BRIDGE',
                              borderColor: const Color(0xFF0AD4F6),
                              onPressed: () {},
                              isTablet: isTablet,
                              disabled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Consumer<WalletStateManager>(
                      builder: (context, walletStateManager, child) {
                        return _buildHistorySection(
                          walletStateManager,
                          isTablet,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthActionButton({
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
    Gradient? gradient,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          gradient: gradient,
          color: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor ?? const Color(0xFF0E0E0E),
              fontSize: isTablet ? 24 : 18,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
