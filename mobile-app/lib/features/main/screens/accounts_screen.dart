import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/main/screens/account_settings_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/create_account_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/models/wallet_state_manager.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';

class AccountDetails {
  final Account account;
  final Future<Map<String, dynamic>> detailsFuture;

  AccountDetails({required this.account, required this.detailsFuture});
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final SettingsService _settingsService = SettingsService();
  final SubstrateService _substrateService = SubstrateService();
  final HumanReadableChecksumService _checksumService =
      HumanReadableChecksumService();
  final NumberFormattingService _formattingService = NumberFormattingService();

  List<AccountDetails> _accountDetails = [];
  Account? _activeAccount;
  bool _isLoading = true;
  bool _isCreatingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _settingsService.getAccounts();
      final activeAccount = await _settingsService.getActiveAccount();

      final detailsFutures = accounts.map((account) {
        try {
          final detailsFuture =
              Future.wait([
                _substrateService.queryBalance(account.accountId),
                _checksumService.getHumanReadableName(account.accountId),
              ]).then(
                (results) => {
                  'balance': results[0] as BigInt,
                  'checksumName': results[1] as String,
                },
              );
          return AccountDetails(account: account, detailsFuture: detailsFuture);
        } catch (e) {
          print('Error fetching details for ${account.accountId}: $e');
          // Return with default/error values if a single account fails
          return AccountDetails(
            account: account,
            detailsFuture: Future.value({
              'balance': BigInt.zero,
              'checksumName': 'Unavailable',
            }),
          );
        }
      }).toList();

      if (mounted) {
        setState(() {
          _accountDetails = detailsFutures;
          _activeAccount = activeAccount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accounts: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createNewAccount() async {
    setState(() {
      _isCreatingAccount = true;
    });
    try {
      final created = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
      );
      if (created == true) {
        await _loadAccounts(); // Reload accounts to show the new one
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/light_leak_effect_background.jpg'),
                fit: BoxFit.cover,
                opacity: 0.54,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const WalletAppBar(title: 'Your Accounts'),

                Expanded(child: _buildAccountsList()),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCreateNewAccountButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.themeColors.circularLoader,
        ),
      );
    }

    if (_accountDetails.isEmpty) {
      return Center(
        child: Text(
          'No accounts found.',
          style: context.themeText.smallParagraph?.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: _accountDetails.length,
      separatorBuilder: (context, index) => const SizedBox(height: 25),
      itemBuilder: (context, index) {
        final details = _accountDetails[index];
        final bool isActive =
            details.account.accountId == _activeAccount?.accountId;
        return _buildAccountListItem(details, isActive, index);
      },
    );
  }

  Widget _buildCreateNewAccountButton() {
    return InkWell(
      onTap: _isCreatingAccount ? null : _createNewAccount,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: context.isTablet ? 18 : 16,
          horizontal: 16,
        ),
        decoration: ShapeDecoration(
          color: Colors.black.useOpacity(0.50),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFE6E6E6)),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isCreatingAccount)
              const CircularProgressIndicator(color: Colors.white)
            else
              Text('Create New Account', style: context.themeText.smallTitle),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountListItem(
    AccountDetails details,
    bool isActive,
    int index,
  ) {
    final account = details.account;

    return InkWell(
      onTap: () {
        if (!isActive) {
          final walletStateManager = Provider.of<WalletStateManager>(
            context,
            listen: false,
          );
          walletStateManager.switchAccount(account);
          if (mounted) Navigator.pop(context);
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              height: context.themeSize.accountListItemHeight,
              decoration: ShapeDecoration(
                color: isActive
                    ? context.themeColors.surfaceActive
                    : context.themeColors.surface,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: context.themeColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    'assets/res_icon.svg',
                    width: context.themeSize.accountListItemLogoWidth,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: details.detailsFuture,
                      builder: (context, snapshot) {
                        String formattedBalance;
                        String humanChecksum;
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          formattedBalance = 'loading balance...';
                          humanChecksum = '';
                        } else {
                          final balance =
                              snapshot.data?['balance'] as BigInt? ??
                              BigInt.zero;
                          final checksumName =
                              snapshot.data?['checksumName'] as String? ??
                              'Unavailable';
                          formattedBalance = _formattingService.formatBalance(
                            balance,
                          );
                          humanChecksum = checksumName;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: context.themeText.smallParagraph?.copyWith(
                                color: isActive ? Colors.black : Colors.white,
                              ),
                            ),
                            Text(
                              humanChecksum,
                              style: context.themeText.detail?.copyWith(
                                color: isActive
                                    ? context.themeColors.checksumDarker
                                    : context.themeColors.checksum,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  context.isTablet
                                      ? account.accountId
                                      : AddressFormattingService.formatAddress(
                                          account.accountId,
                                        ),
                                  style: context.themeText.tiny?.copyWith(
                                    color: isActive
                                        ? context.themeColors.darkGray
                                        : context.themeColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () => ClipboardExtensions.copyText(
                                    context,
                                    account.accountId,
                                  ),
                                  child: Icon(
                                    Icons.copy,
                                    size: context.isTablet ? 20 : 14,
                                    color: isActive
                                        ? context.themeColors.darkGray
                                        : context.themeColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: formattedBalance,
                                    style: context.themeText.tiny?.copyWith(
                                      color: isActive
                                          ? context.themeColors.darkGray
                                          : context.themeColors.light,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${AppConstants.tokenSymbol}',
                                    style: context.themeText.tiny?.copyWith(
                                      color: isActive
                                          ? context.themeColors.darkGray
                                          : context.themeColors.light,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 0),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: SvgPicture.asset(
              'assets/settings_icon_off.svg',
              width: context.isTablet ? 28 : 21,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () async {
              final accountDetails = await details.detailsFuture;
              final checksumName = accountDetails['checksumName'] as String;
              final balance = accountDetails['balance'] as BigInt;
              if (!mounted) return;
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettingsScreen(
                    account: account,
                    balance:
                        // ignore: lines_longer_than_80_chars
                        '${_formattingService.formatBalance(balance)} ${AppConstants.tokenSymbol}',
                    checksumName: checksumName,
                  ),
                ),
              );
              if (result == true) {
                _loadAccounts();
                if (mounted) {
                  Provider.of<WalletStateManager>(
                    context,
                    listen: false,
                  ).refreshActiveAccount();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
