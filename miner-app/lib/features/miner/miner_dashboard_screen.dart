import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:quantus_miner/src/services/miner_process.dart'; // Import MinerProcess
import 'package:quantus_miner/src/services/miner_settings_service.dart'; // Import the new service
import 'package:quantus_miner/src/services/mining_stats_service.dart'; // Import mining stats service
import 'package:quantus_miner/src/ui/logs_widget.dart'; // Import LogsWidget
import 'package:quantus_miner/src/ui/miner_controls.dart'; // Import MinerControls
import 'package:quantus_sdk/quantus_sdk.dart'; // Assuming quantus_sdk exports necessary components

// Remove explicit imports for internal SDK files
// import 'package:quantus_sdk/src/rust/api/crypto.dart' as crypto;
// import 'package:quantus_sdk/src/services/substrate_service.dart';

// --- Updated Menu Enum ---
enum _MenuValues {
  logout, // Changed from resetApp to logout
}
// --- End Updated Menu Enum ---

class MinerDashboardScreen extends StatefulWidget {
  const MinerDashboardScreen({super.key});

  @override
  State<MinerDashboardScreen> createState() => _MinerDashboardScreenState();
}

class _MinerDashboardScreenState extends State<MinerDashboardScreen> {
  String _walletBalance = 'Loading...';
  String? _walletAddress;
  MiningStats? _miningStats;
  MinerProcess? _currentMinerProcess;

  final _storage = const FlutterSecureStorage(); // Instantiate secure storage
  final _minerSettingsService =
      MinerSettingsService(); // Instantiate the service
  final _miningStatsService =
      MiningStatsService(); // Instantiate mining stats service

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _startMiningStatsMonitoring();
  }

  @override
  void dispose() {
    _miningStatsService.stopMonitoring();
    super.dispose();
  }

  void _startMiningStatsMonitoring() {
    _miningStatsService.startMonitoring();
    _miningStatsService.statsStream.listen((stats) {
      if (mounted) {
        setState(() {
          _miningStats = stats;
        });
      }
    });
  }

  void _onMinerProcessChanged(MinerProcess? minerProcess) {
    if (mounted) {
      setState(() {
        _currentMinerProcess = minerProcess;
      });
    }
    // Connect miner process to mining stats service for real hashrate
    _miningStatsService.setMinerProcess(minerProcess);
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

  // --- Renamed and Updated Method for Logout ---
  Future<void> _performLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text(
            'This will delete your stored rewards address mnemonic, node identity, and the downloaded node binary. You will need to go through the full setup process again.\n\nAre you sure you want to continue?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _minerSettingsService.logout(); // Call the service method
      if (mounted) {
        context.go('/node_setup'); // Navigate to the first setup screen
      }
    }
  }
  // --- End Renamed and Updated Method for Logout ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantus Miner'),
        actions: [
          PopupMenuButton<_MenuValues>(
            onSelected: (_MenuValues item) async {
              switch (item) {
                case _MenuValues.logout: // Updated to logout
                  await _performLogout(); // Call the new logout method
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_MenuValues>>[
                  const PopupMenuItem<_MenuValues>(
                    value: _MenuValues.logout, // Updated to logout
                    child: Text('Logout (Full Reset)'), // Updated text
                  ),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Balance Section (Left)
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Wallet Balance:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Reload Balance',
                                  onPressed: _fetchWalletBalance,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _walletBalance,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_walletAddress != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _walletAddress!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontFamily: 'Fira Code',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Mine Button Section (Right)
                  Expanded(
                    flex: 1,
                    child: MinerControls(
                      onMinerProcessChanged: _onMinerProcessChanged,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats Panel (Below)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mining Stats:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_miningStats != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _miningStats!.isSyncing
                                  ? Colors.orange
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _miningStats!.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_miningStats != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Peers: ${_miningStats!.peerCount}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 24),
                              const Icon(
                                Icons.block,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Block: ${_miningStats!.currentBlock}/${_miningStats!.targetBlock}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.speed,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hashrate: ${_miningStats!.hashrate.toStringAsFixed(2)} H/s',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Loading mining stats...',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Logs Panel
            Expanded(
              child: LogsWidget(
                minerProcess: _currentMinerProcess,
                maxLines: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
