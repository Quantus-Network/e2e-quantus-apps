import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/mining_stats_service.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';

import '../../src/services/binary_manager.dart';
import '../../src/services/miner_process.dart';
import '../../main.dart'; // Import for GlobalMinerManager
// PrometheusService import might not be needed here anymore if hashrate is exclusively from MinerProcess
// import '../services/prometheus_service.dart';

class MinerControls extends StatefulWidget {
  final MiningStats miningStats;
  final Function(MiningStats) onMetricsUpdate;
  final Function(MinerProcess?)? onMinerProcessChanged;

  const MinerControls({
    super.key,
    required this.miningStats,
    required this.onMetricsUpdate,
    this.onMinerProcessChanged,
  });

  @override
  State<MinerControls> createState() => _MinerControlsState();
}

class _MinerControlsState extends State<MinerControls> {
  MinerProcess? _proc;
  // Timer? _poll; // Removed: Hashrate will come from MinerProcess callback
  bool _isAttemptingToggle = false;

  Future<void> _toggle() async {
    if (_isAttemptingToggle) return;
    setState(() => _isAttemptingToggle = true);

    if (_proc == null) {
      print('Starting mining');

      // Check for all required files and binaries
      final id = File('${await BinaryManager.getQuantusHomeDirectoryPath()}/node_key.p2p');
      final rew = File('${await BinaryManager.getQuantusHomeDirectoryPath()}/rewards-address.txt');
      final binPath = await BinaryManager.getNodeBinaryFilePath();
      final bin = File(binPath);
      final minerBinPath = await BinaryManager.getExternalMinerBinaryFilePath();
      final minerBin = File(minerBinPath);

      // Check node binary
      if (!await bin.exists()) {
        print('Node binary not found. Cannot start mining.');
        if (mounted) {
          context.showWarningSnackbar(title: 'Node binary not found!', message: 'Please run setup.');
        }
        setState(() => _isAttemptingToggle = false);
        return;
      }

      // Check external miner binary
      if (!await minerBin.exists()) {
        print('External miner binary not found. Cannot start mining.');
        if (mounted) {
          context.showWarningSnackbar(title: 'External miner binary not found!', message: 'Please run setup.');
        }
        setState(() => _isAttemptingToggle = false);
        return;
      }

      _proc = MinerProcess(
        bin,
        id,
        rew,
        onStatsUpdate: widget.onMetricsUpdate,
      );

      // Notify parent about the new miner process
      widget.onMinerProcessChanged?.call(_proc);

      try {
        final newMiningStats = widget.miningStats.copyWith(isSyncing: true, status: MiningStatus.syncing);
        widget.onMetricsUpdate(newMiningStats);
        await _proc!.start();
        // _poll Timer removed - no longer fetching hashrate from here
      } catch (e) {
        print('Error starting miner process: $e');
        if (mounted) {
          context.showErrorSnackbar(title: 'Error starting miner!', message: e.toString());
        }
        _proc = null;
        // Notify parent that miner process is null
        widget.onMinerProcessChanged?.call(null);
        final newMiningStats = MiningStats.empty();
        widget.onMetricsUpdate(newMiningStats);
      }
    } else {
      print('Stopping mining');

      try {
        _proc!.stop();
        // Wait a moment for graceful shutdown
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('Error during graceful stop: $e');
      }

      // Use GlobalMinerManager for comprehensive cleanup
      await GlobalMinerManager.cleanup();

      // _poll?.cancel(); // _poll removed
      _proc = null;
      // Notify parent that miner process is stopped
      widget.onMinerProcessChanged?.call(null);
      final newMiningStats = MiningStats.empty();
      widget.onMetricsUpdate(newMiningStats);
    }
    if (mounted) {
      setState(() => _isAttemptingToggle = false);
    }
  }

  @override
  void dispose() {
    // _poll?.cancel(); // _poll removed
    if (_proc != null) {
      print('MinerControls: disposing, force stopping miner process');

      try {
        _proc!.forceStop();
      } catch (e) {
        print('MinerControls: Error force stopping miner process in dispose: $e');
      }

      // Use GlobalMinerManager for comprehensive cleanup
      GlobalMinerManager.cleanup();

      _proc = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _proc == null ? Colors.green : Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        minimumSize: const Size(200, 50),
      ),
      onPressed: _isAttemptingToggle ? null : _toggle,
      child: Text(_proc == null ? 'Start Mining' : 'Stop Mining'),
    );
  }
}
