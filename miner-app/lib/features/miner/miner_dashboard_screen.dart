import 'package:flutter/material.dart';
import 'package:quantus_miner/features/miner/miner_balance_card.dart';
import 'package:quantus_miner/features/miner/miner_app_bar.dart';
import 'package:quantus_miner/features/miner/miner_stats_card.dart';
import 'package:quantus_miner/features/miner/miner_status.dart';
import 'package:quantus_miner/src/services/miner_process.dart';
import 'package:quantus_miner/src/services/mining_stats_service.dart';
import 'package:quantus_miner/src/ui/logs_widget.dart';
import 'package:quantus_miner/features/miner/miner_controls.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import '../../main.dart';

class MinerDashboardScreen extends StatefulWidget {
  const MinerDashboardScreen({super.key});

  @override
  State<MinerDashboardScreen> createState() => _MinerDashboardScreenState();
}

class _MinerDashboardScreenState extends State<MinerDashboardScreen> {
  MiningStats _miningStats = MiningStats.empty();
  MinerProcess? _currentMinerProcess;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up global miner process
    if (_currentMinerProcess != null) {
      try {
        _currentMinerProcess!.forceStop();
      } catch (e) {
        print('MinerDashboard: Error stopping miner process on dispose: $e');
      }
    }
    GlobalMinerManager.cleanup();

    super.dispose();
  }

  void _onMetricsUpdate(MiningStats miningStats) {
    setState(() {
      _miningStats = miningStats;
    });
  }

  void _onMinerProcessChanged(MinerProcess? minerProcess) {
    if (mounted) {
      setState(() {
        _currentMinerProcess = minerProcess;
      });
    }

    // Register with global app lifecycle for cleanup
    GlobalMinerManager.setMinerProcess(minerProcess);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Deep space black
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                ),
              ),
            ),
            // Main content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom app bar with glass effect
                MinerAppBar(),

                // Main content
                SliverPadding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      MinerStatus(miningStats: _miningStats),

                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400),
                          child: SizedBox(
                            width: double.infinity,
                            child: MinerControls(
                              miningStats: _miningStats,
                              onMetricsUpdate: _onMetricsUpdate,
                              onMinerProcessChanged: _onMinerProcessChanged,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      _buildResponsiveCards(),
                    ]),
                  ),
                ),

                // Logs section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Container(
                      height: 430,
                      decoration: BoxDecoration(
                        color: Colors.white.useOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.useOpacity(0.1), width: 1),
                      ),
                      child: Column(
                        children: [
                          // Logs header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white.useOpacity(0.1), width: 1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.terminal, color: Colors.white.useOpacity(0.7), size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'Live Logs',
                                  style: TextStyle(
                                    color: Colors.white.useOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Logs content
                          Expanded(child: LogsWidget(minerProcess: _currentMinerProcess, maxLines: 200)),
                        ],
                      ),
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

  Widget _buildResponsiveCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            children: [
              Expanded(child: MinerBalanceCard()),
              const SizedBox(width: 16),
              Expanded(child: MinerStatsCard(miningStats: _miningStats)),
            ],
          );
        } else {
          return Column(
            children: [
              MinerBalanceCard(),
              MinerStatsCard(miningStats: _miningStats),
            ],
          );
        }
      },
    );
  }
}
