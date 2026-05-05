import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantus_miner/features/settings/settings_app_bar.dart';
import 'package:quantus_miner/src/services/binary_manager.dart';
import 'package:quantus_miner/src/services/miner_wallet_service.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BinaryVersion? _minerUpdateInfo;
  BinaryVersion? _nodeUpdateInfo;
  bool _isLoading = true;

  final MinerWalletService _walletService = MinerWalletService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final [nodeUpdateInfo, minerUpdateInfo] = await Future.wait([
      BinaryManager.getNodeBinaryVersion(),
      BinaryManager.getMinerBinaryVersion(),
    ]);

    if (mounted) {
      setState(() {
        _minerUpdateInfo = minerUpdateInfo;
        _nodeUpdateInfo = nodeUpdateInfo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a theme-consistent accent color (e.g., a tech green or teal)
    const Color accentColor = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Deep space black
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0A0A), Color(0xFF141414)],
                ),
              ),
            ),

            // Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SettingsAppBar(), // Assuming this is a SliverAppBar or similar

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Text(
                          'SYSTEM INFORMATION',
                          style: TextStyle(
                            color: Colors.white.useOpacity(0.5),
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Node Binary Card
                        _buildInfoTile(
                          title: 'Node Version',
                          version: _nodeUpdateInfo?.version,
                          icon: Icons.dns_rounded,
                          accentColor: accentColor,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 12),

                        // Miner Binary Card
                        _buildInfoTile(
                          title: 'Miner Version',
                          version: _minerUpdateInfo?.version,
                          icon: Icons.memory_rounded, // Chip icon suits "Miner"
                          accentColor: accentColor,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 32),

                        // Wallet Section Header
                        Text(
                          'WALLET',
                          style: TextStyle(
                            color: Colors.white.useOpacity(0.5),
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Inner hash button
                        _buildActionTile(
                          title: 'View Inner Hash',
                          subtitle: 'Copy the inner hash used by the miner',
                          icon: Icons.shield_outlined,
                          accentColor: const Color(0xFFFF9800),
                          onTap: _showInnerHashDialog,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String? version,
    required IconData icon,
    required Color accentColor,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.useOpacity(0.05), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.useOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.useOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          // Version Number or Loading
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.useOpacity(0.3)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.useOpacity(0.1)),
              ),
              child: Text(
                version ?? 'Unknown',
                style: TextStyle(
                  color: Colors.white.useOpacity(0.9),
                  fontFamily: 'Courier', // Monospace for tech feel
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.useOpacity(0.05), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.useOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accentColor.useOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.useOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: Colors.white.useOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Future<void> _showInnerHashDialog() async {
    final innerHash = await _walletService.getRewardsInnerHash();

    if (innerHash == null || innerHash.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No inner hash found. Please set up your wallet first.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            const Text('Inner Hash', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.useOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.useOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anyone with this inner hash can direct mining rewards to the associated address.',
                        style: TextStyle(color: Colors.orange.useOpacity(0.9), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.useOpacity(0.1)),
                ),
                child: SelectableText(
                  innerHash,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use this value in the miner setup flow or copy it into your CLI workflow:',
                style: TextStyle(color: Colors.white.useOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: innerHash));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inner hash copied to clipboard'),
                  backgroundColor: Color(0xFF00E676),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copy Inner Hash', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
