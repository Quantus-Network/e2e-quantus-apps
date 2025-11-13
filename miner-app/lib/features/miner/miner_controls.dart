import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/mining_stats_service.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';

import '../../src/services/binary_manager.dart';
import '../../src/services/miner_process.dart';
import '../../main.dart';

class MinerControls extends StatefulWidget {
  final MinerProcess? minerProcess;
  final MiningStats miningStats;
  final Function(MiningStats) onMetricsUpdate;
  final Function(MinerProcess?) onMinerProcessChanged;

  const MinerControls({
    super.key,
    required this.minerProcess,
    required this.miningStats,
    required this.onMetricsUpdate,
    required this.onMinerProcessChanged,
  });

  @override
  State<MinerControls> createState() => _MinerControlsState();
}

class _MinerControlsState extends State<MinerControls> {
  bool _isAttemptingToggle = false;

  Future<void> _toggle() async {
    if (_isAttemptingToggle) return;
    setState(() => _isAttemptingToggle = true);

    if (widget.minerProcess == null) {
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

      final newProc = MinerProcess(bin, id, rew, onStatsUpdate: widget.onMetricsUpdate);
      // Notify parent about the new miner process
      widget.onMinerProcessChanged.call(newProc);

      try {
        final newMiningStats = widget.miningStats.copyWith(isSyncing: true, status: MiningStatus.syncing);
        widget.onMetricsUpdate(newMiningStats);
        await newProc.start();
      } catch (e) {
        print('Error starting miner process: $e');
        if (mounted) {
          context.showErrorSnackbar(title: 'Error starting miner!', message: e.toString());
        }

        // Notify parent that miner process is null
        widget.onMinerProcessChanged.call(null);
        final newMiningStats = MiningStats.empty();
        widget.onMetricsUpdate(newMiningStats);
      }
    } else {
      print('Stopping mining');

      try {
        widget.minerProcess!.stop();
        // Wait a moment for graceful shutdown
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('Error during graceful stop: $e');
      }

      await GlobalMinerManager.cleanup();

      // Notify parent that miner process is stopped
      widget.onMinerProcessChanged.call(null);
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
    if (widget.minerProcess != null) {
      print('MinerControls: disposing, force stopping miner process');

      try {
        widget.minerProcess!.forceStop();
      } catch (e) {
        print('MinerControls: Error force stopping miner process in dispose: $e');
      }

      // Use GlobalMinerManager for comprehensive cleanup
      GlobalMinerManager.cleanup();

      widget.onMinerProcessChanged.call(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.minerProcess == null ? Colors.green : Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        minimumSize: const Size(200, 50),
      ),
      onPressed: _isAttemptingToggle ? null : _toggle,
      child: Text(widget.minerProcess == null ? 'Start Mining' : 'Stop Mining'),
    );
  }
}
