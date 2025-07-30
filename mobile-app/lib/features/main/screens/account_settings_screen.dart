import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/main/screens/create_account_screen.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class AccountSettingsScreen extends StatefulWidget {
  final Account account;
  final String balance;
  final String checksumName;

  const AccountSettingsScreen({
    super.key,
    required this.account,
    required this.balance,
    required this.checksumName,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  void _editAccountName() {
    Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateAccountScreen(accountToEdit: widget.account),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Pop this screen with a result to force a refresh on the previous one
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

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
          child: Column(
            children: [
              const WalletAppBar(title: 'Account Settings'),
              const SizedBox(height: 20),
              _buildAccountHeader(isTablet),
              const SizedBox(height: 40),
              _buildAddressSection(isTablet),
              const SizedBox(height: 20),
              _buildSecuritySection(isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHeader(bool isTablet) {
    return Column(
      children: [
        // Placeholder for account icon
        SvgPicture.asset('assets/res_icon.svg', width: isTablet ? 80 : 60),
        const SizedBox(height: 10),
        InkWell(
          onTap: _editAccountName,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.account.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 24 : 16,
                  fontFamily: 'Fira Code',
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit, color: Colors.white70, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.checksumName,
          style: TextStyle(
            color: const Color(0xFF16CECE),
            fontSize: isTablet ? 20 : 14,
            fontFamily: 'Fira Code',
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.balance,
          style: TextStyle(
            color: const Color(0xFFE6E6E6),
            fontSize: isTablet ? 18 : 14,
            fontFamily: 'Fira Code',
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isTablet ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF313131),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!isTablet) const Expanded(child: SizedBox()),
            SizedBox(
              width: isTablet ? 550 : 180,
              child: Text(
                isTablet
                    ? widget.account.accountId
                    : AddressFormattingService.splitIntoChunks(
                        widget.account.accountId,
                      ).join(' '),
                textAlign: isTablet ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                  fontFamily: 'Fira Code',
                ),
              ),
            ),
            if (!isTablet) const Expanded(child: SizedBox()),
            IconButton(
              icon: Icon(
                Icons.copy,
                color: Colors.white,
                size: isTablet ? 26 : 22,
              ),
              onPressed: () => ClipboardExtensions.copyAddress(
                context,
                widget.account.accountId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF313131),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/lock_icon.svg',
                  width: isTablet ? 28 : 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'High Security Features',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 22 : 16,
                        fontFamily: 'Fira Code',
                      ),
                    ),
                    Text(
                      'COMING SOON',
                      style: TextStyle(
                        color: const Color(0xFFFADC34),
                        fontSize: isTablet ? 18 : 12,
                        fontFamily: 'Fira Code',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
