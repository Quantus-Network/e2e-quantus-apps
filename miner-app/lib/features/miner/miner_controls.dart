import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quantus_miner/src/services/mining_orchestrator.dart';
import 'package:quantus_miner/src/services/mining_stats_service.dart';
import 'package:quantus_miner/src/shared/extensions/snackbar_extensions.dart';

import '../../main.dart';
import '../../src/services/binary_manager.dart';
import '../../src/services/gpu_detection_service.dart';
import '../../src/services/miner_settings_service.dart';

class MinerControls extends StatefulWidget {
  final MiningOrchestrator? orchestrator;
  final MiningStats miningStats;
  final Function(MiningOrchestrator?) onOrchestratorChanged;

  const MinerControls({
    super.key,
    required this.orchestrator,
    required this.miningStats,
    required this.onOrchestratorChanged,
  });

  @override
  State<MinerControls> createState() => _MinerControlsState();
}

class _MinerControlsState extends State<MinerControls> {
  bool _isAttemptingToggle = false;
  int _cpuWorkers = 8;
  int _gpuDevices = 0;
  int _detectedGpuCount = 0;
  String _chainId = 'dev';
  final _settingsService = MinerSettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _detectHardware();
  }

  Future<void> _loadSettings() async {
    final savedCpuWorkers = await _settingsService.getCpuWorkers();
    final savedGpuDevices = await _settingsService.getGpuDevices();
    final savedChainId = await _settingsService.getChainId();

    if (mounted) {
      setState(() {
        _cpuWorkers =
            savedCpuWorkers ??
            (Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 8);
        _gpuDevices = savedGpuDevices ?? 0;
        _chainId = savedChainId;
      });
    }
  }

  Future<void> _detectHardware() async {
    final gpuCount = await GpuDetectionService.detectGpuCount();
    if (mounted) {
      setState(() {
        _detectedGpuCount = gpuCount;
      });
    }
  }

  Future<void> _toggle() async {
    if (_isAttemptingToggle) return;
    setState(() => _isAttemptingToggle = true);

    if (widget.orchestrator == null || !widget.orchestrator!.isMining) {
      // Start mining
      await _startMining();
    } else {
      // Stop mining
      await _stopMining();
    }

    if (mounted) {
      setState(() => _isAttemptingToggle = false);
    }
  }

  Future<void> _startMining() async {
    print('Starting mining');

    // Check for all required files and binaries
    final quantusHome = await BinaryManager.getQuantusHomeDirectoryPath();
    final identityFile = File('$quantusHome/node_key.p2p');
    final rewardsFile = File('$quantusHome/rewards-address.txt');
    final nodeBinPath = await BinaryManager.getNodeBinaryFilePath();
    final nodeBin = File(nodeBinPath);
    final minerBinPath = await BinaryManager.getExternalMinerBinaryFilePath();
    final minerBin = File(minerBinPath);

    // Check node binary
    if (!await nodeBin.exists()) {
      print('Node binary not found. Cannot start mining.');
      if (mounted) {
        context.showWarningSnackbar(
          title: 'Node binary not found!',
          message: 'Please run setup.',
        );
      }
      return;
    }

    // Check external miner binary
    if (!await minerBin.exists()) {
      print('External miner binary not found. Cannot start mining.');
      if (mounted) {
        context.showWarningSnackbar(
          title: 'External miner binary not found!',
          message: 'Please run setup.',
        );
      }
      return;
    }

    // Create new orchestrator
    final orchestrator = MiningOrchestrator();
    widget.onOrchestratorChanged(orchestrator);

    try {
      await orchestrator.start(
        MiningSessionConfig(
          nodeBinary: nodeBin,
          minerBinary: minerBin,
          identityFile: identityFile,
          rewardsFile: rewardsFile,
          chainId: _chainId,
          cpuWorkers: _cpuWorkers,
          gpuDevices: _gpuDevices,
          detectedGpuCount: _detectedGpuCount,
        ),
      );
    } catch (e) {
      print('Error starting miner: $e');
      if (mounted) {
        context.showErrorSnackbar(
          title: 'Error starting miner!',
          message: e.toString(),
        );
      }

      // Clean up on failure
      orchestrator.dispose();
      widget.onOrchestratorChanged(null);
    }
  }

  Future<void> _stopMining() async {
    print('Stopping mining');

    if (widget.orchestrator != null) {
      try {
        await widget.orchestrator!.stop();
      } catch (e) {
        print('Error during stop: $e');
      }

      widget.orchestrator!.dispose();
    }

    await GlobalMinerManager.cleanup();
    widget.onOrchestratorChanged(null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isMining => widget.orchestrator?.isMining ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CPU Workers Control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CPU Workers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$_cpuWorkers'),
                ],
              ),
              Slider(
                value: _cpuWorkers.toDouble(),
                min: 0,
                max:
                    (Platform.numberOfProcessors > 0
                            ? Platform.numberOfProcessors
                            : 16)
                        .toDouble(),
                divisions: (Platform.numberOfProcessors > 0
                    ? Platform.numberOfProcessors
                    : 16),
                label: _cpuWorkers.toString(),
                onChanged: !_isMining
                    ? (value) {
                        final rounded = value.round();
                        setState(() => _cpuWorkers = rounded);
                        _settingsService.saveCpuWorkers(rounded);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // GPU Devices Control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GPU Devices',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$_gpuDevices / $_detectedGpuCount'),
                ],
              ),
              Slider(
                value: _gpuDevices.toDouble(),
                min: 0,
                max: _detectedGpuCount > 0 ? _detectedGpuCount.toDouble() : 1,
                divisions: _detectedGpuCount > 0 ? _detectedGpuCount : 1,
                label: _gpuDevices.toString(),
                onChanged: !_isMining
                    ? (value) {
                        final rounded = value.round();
                        setState(() => _gpuDevices = rounded);
                        _settingsService.saveGpuDevices(rounded);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: !_isMining ? Colors.green : Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            minimumSize: const Size(200, 50),
          ),
          onPressed: _isAttemptingToggle ? null : _toggle,
          child: Text(!_isMining ? 'Start Mining' : 'Stop Mining'),
        ),
      ],
    );
  }
}
