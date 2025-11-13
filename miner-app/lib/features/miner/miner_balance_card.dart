import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class MinerBalanceCard extends StatefulWidget {
  const MinerBalanceCard({super.key});

  @override
  State<MinerBalanceCard> createState() => _MinerBalanceCardState();
}

class _MinerBalanceCardState extends State<MinerBalanceCard> {
  String _walletBalance = 'Loading...';
  String? _walletAddress;
  Timer? _balanceTimer;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _fetchWalletBalance();
    // Start automatic polling every 30 seconds
    _balanceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchWalletBalance();
    });
  }

  @override
  void dispose() {
    _balanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWalletBalance() async {
    // Implement actual wallet balance fetching using quantus_sdk
    String? address;
    print('fetching wallet balance');
    try {
      final mnemonic = await _storage.read(key: 'rewards_address_mnemonic');
      print('mnemonic: ${mnemonic?.split(" ").length} words');
      if (mnemonic != null) {
        // Derive keypair from mnemonic using SubstrateService (exported by quantus_sdk)
        // ignore: deprecated_member_use
        final keypair = SubstrateService().nonHDdilithiumKeypairFromMnemonic(
          mnemonic,
        );
        // Use toAccountId function to get the SS58 address (exported by quantus_sdk)
        address = toAccountId(obj: keypair);

        print('address: $address');

        // Fetch balance using SubstrateService (exported by quantus_sdk)
        final balance = await SubstrateService().queryBalance(address);

        print('balance: $balance');

        setState(() {
          // Assuming NumberFormattingService and AppConstants are available via quantus_sdk export
          _walletBalance = NumberFormattingService().formatBalance(
            balance,
            addSymbol: true,
          );
          _walletAddress = address;
        });
      } else {
        setState(() {
          _walletBalance = 'Address not set';
          _walletAddress = null;
        });
        print('Rewards address mnemonic not found. Redirecting to setup...');
        // Example Navigation (requires go_router setup)
        // context.go('/rewards_address_setup');
      }
    } catch (e) {
      setState(() {
        _walletBalance = 'Error fetching balance';
        _walletAddress = address;
      });
      print('Error fetching wallet balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.useOpacity(0.1), Colors.white.useOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.useOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.useOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1), // Deep purple
                        Color(0xFF1E3A8A), // Deep blue
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.useOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _walletBalance,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1), // Deep purple
                letterSpacing: -1,
              ),
            ),
            if (_walletAddress != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.useOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.useOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      color: Colors.white.useOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _walletAddress!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.useOpacity(0.6),
                          fontFamily: 'Fira Code',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Colors.white.useOpacity(0.5),
                        size: 16,
                      ),
                      onPressed: () {
                        if (_walletAddress != null) {
                          context.copyTextWithSnackbar(_walletAddress!);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
