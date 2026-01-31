import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quantus_miner/src/config/miner_config.dart';
import 'package:quantus_miner/src/services/process_cleanup_service.dart';
import 'package:quantus_miner/src/services/prometheus_service.dart';
import 'package:quantus_miner/src/shared/extensions/log_string_extension.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';

import './binary_manager.dart';
import './chain_rpc_client.dart';
import './external_miner_api_client.dart';
import './log_filter_service.dart';
import './mining_stats_service.dart';

final _log = log.withTag('MinerProcess');

class LogEntry {
  final String message;
  final DateTime timestamp;
  final String source; // 'node', 'quantus-miner', 'error'

  LogEntry({
    required this.message,
    required this.timestamp,
    required this.source,
  });

  @override
  String toString() {
    final timeStr = timestamp.toIso8601String().substring(11, 19); // HH:MM:SS
    return '[$timeStr] [$source] $message';
  }
}

/// quantus_sdk/lib/src/services/miner_process.dart
class MinerProcess {
  final File bin;
  final File identityPath;
  final File rewardsPath;
  late Process _nodeProcess;
  Process? _externalMinerProcess;
  late LogFilterService _stdoutFilter;
  late LogFilterService _stderrFilter;

  late MiningStatsService _statsService;
  late PrometheusService _prometheusService;
  late ExternalMinerApiClient _externalMinerApiClient;
  late PollingChainRpcClient _chainRpcClient;

  Timer? _syncStatusTimer;
  final int cpuWorkers;
  final int gpuDevices;

  final int minerListenPort;
  final int detectedGpuCount;
  final String chainId;

  // Track metrics state to prevent premature hashrate reset
  double _lastValidHashrate = 0.0;
  int _consecutiveMetricsFailures = 0;

  // Public getters for process PIDs (for cleanup tracking)
  int? get nodeProcessPid {
    try {
      return _nodeProcess.pid;
    } catch (e) {
      return null;
    }
  }

  int? get externalMinerProcessPid {
    try {
      return _externalMinerProcess?.pid;
    } catch (e) {
      return null;
    }
  }

  // Stream for logs
  final _logsController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logsStream => _logsController.stream;

  final Function(MiningStats stats)? onStatsUpdate;

  MinerProcess(
    this.bin,
    this.identityPath,
    this.rewardsPath, {
    this.onStatsUpdate,
    this.cpuWorkers = 8,
    this.gpuDevices = 0,
    this.detectedGpuCount = 0,
    this.minerListenPort = 9833,
    this.chainId = 'dev',
  }) {
    // Initialize services
    _statsService = MiningStatsService();
    _prometheusService = PrometheusService();
    _stdoutFilter = LogFilterService();
    _stderrFilter = LogFilterService();

    // Initialize external miner API client with metrics endpoint
    _externalMinerApiClient = ExternalMinerApiClient(
      metricsUrl: MinerConfig.minerMetricsUrl(
        MinerConfig.defaultMinerMetricsPort,
      ),
    );

    // Set up external miner API callbacks
    _externalMinerApiClient.onMetricsUpdate = _handleExternalMinerMetrics;
    _externalMinerApiClient.onError = _handleExternalMinerError;

    // Initialize chain RPC client
    _chainRpcClient = PollingChainRpcClient(
      rpcUrl: MinerConfig.nodeRpcUrl(MinerConfig.defaultNodeRpcPort),
    );
    _chainRpcClient.onChainInfoUpdate = _handleChainInfoUpdate;
    _chainRpcClient.onError = _handleChainRpcError;

    // Initialize stats with the configured worker count
    _statsService.updateWorkers(cpuWorkers);
    // Initialize stats with total CPU capacity from platform
    _statsService.updateCpuCapacity(Platform.numberOfProcessors);
    // Initialize stats with the configured GPU devices
    _statsService.updateGpuDevices(gpuDevices);
    // Initialize stats with total GPU capacity from detection
    _statsService.updateGpuCapacity(detectedGpuCount);
  }

  Future<void> start() async {
    // First, ensure both binaries are available
    await BinaryManager.ensureNodeBinary();
    await BinaryManager.ensureExternalMinerBinary();

    // Perform pre-start cleanup using the cleanup service
    await ProcessCleanupService.performPreStartCleanup(chainId);

    // Check if ports are available and cleanup if needed
    await _ensurePortsAvailable();

    // === START NODE FIRST (QUIC server) ===
    final quantusHome = await BinaryManager.getQuantusHomeDirectoryPath();
    final basePath = p.join(quantusHome, 'node_data');
    await Directory(basePath).create(recursive: true);

    final nodeKeyFileFromFileSystem = await BinaryManager.getNodeKeyFile();
    if (await nodeKeyFileFromFileSystem.exists()) {
      final stat = await nodeKeyFileFromFileSystem.stat();
      _log.d(
        'Node key file exists (${nodeKeyFileFromFileSystem.path}), size: ${stat.size} bytes',
      );
    } else {
      _log.d('Node key file does not exist: ${nodeKeyFileFromFileSystem.path}');
    }

    if (!await identityPath.exists()) {
      throw Exception('Identity file not found: ${identityPath.path}');
    }

    // Read the rewards address from the file
    String rewardsAddress;
    try {
      if (!await rewardsPath.exists()) {
        throw Exception('Rewards address file not found: ${rewardsPath.path}');
      }
      rewardsAddress = await rewardsPath.readAsString();
      rewardsAddress = rewardsAddress.trim(); // Remove any whitespace/newlines
      _log.d('Read rewards address: $rewardsAddress');
    } catch (e) {
      throw Exception(
        'Failed to read rewards address from file ${rewardsPath.path}: $e',
      );
    }

    final List<String> args = [
      '--base-path',
      basePath,
      '--node-key-file',
      identityPath.path,
      '--rewards-address',
      rewardsAddress,
      '--validator',
      // Use --dev for local development, --chain for testnet/mainnet
      if (chainId == 'dev') '--dev' else ...['--chain', chainId],
      '--port',
      '30333',
      '--prometheus-port',
      '9616',
      '--experimental-rpc-endpoint',
      'listen-addr=127.0.0.1:9933,methods=unsafe,cors=all',
      '--name',
      'QuantusMinerGUI',
      '--miner-listen-port',
      minerListenPort.toString(),
      '--enable-peer-sharing',
    ];

    _log.d('Executing: ${bin.path} ${args.join(' ')}');

    _nodeProcess = await Process.start(bin.path, args);
    _stdoutFilter = LogFilterService();
    _stderrFilter = LogFilterService();

    _stdoutFilter.reset();
    _stderrFilter.reset();

    // Process each log line
    void processLogLine(String line, String streamType) {
      bool shouldPrint;
      if (streamType == 'stdout') {
        shouldPrint = _stdoutFilter.shouldPrintLine(
          line,
          isNodeSyncing: _statsService.currentStats.isSyncing,
        );
      } else {
        shouldPrint = _stderrFilter.shouldPrintLine(
          line,
          isNodeSyncing: _statsService.currentStats.isSyncing,
        );
      }

      if (shouldPrint) {
        String source;
        if (line.isNodeError) {
          source = 'node-error';
        } else if (streamType == 'stdout') {
          source = 'node';
        } else {
          source = 'node';
        }

        final logEntry = LogEntry(
          message: line,
          timestamp: DateTime.now(),
          source: source,
        );
        _logsController.add(logEntry);
        if (source == 'node-error') {
          _log.w('[node] $line');
        } else {
          _log.d('[node] $line');
        }
      }
    }

    _nodeProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          processLogLine(line, 'stdout');
        });

    _nodeProcess.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          processLogLine(line, 'stderr');
        });

    Future<void> syncBlockTargetWithPrometheusMetrics() async {
      try {
        final metrics = await _prometheusService.fetchMetrics();
        if (metrics == null || metrics.targetBlock == null) return;
        if (_statsService.currentStats.targetBlock >= metrics.targetBlock!) {
          return;
        }

        _statsService.updateTargetBlock(metrics.targetBlock!);

        onStatsUpdate?.call(_statsService.currentStats);
      } catch (e) {
        _log.w('Failed to fetch target block height', error: e);
      }
    }

    // Start Prometheus polling for target block (every 3 seconds)
    _syncStatusTimer?.cancel();
    _syncStatusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => syncBlockTargetWithPrometheusMetrics(),
    );

    // Wait for node RPC to be ready before starting miner
    await _waitForNodeRpcReady();

    // === START MINER (QUIC client connects to node) ===
    final externalMinerBinPath =
        await BinaryManager.getExternalMinerBinaryFilePath();
    final externalMinerBin = File(externalMinerBinPath);

    if (!await externalMinerBin.exists()) {
      throw Exception(
        'External miner binary not found at $externalMinerBinPath',
      );
    }

    final minerArgs = [
      '--node-addr',
      '127.0.0.1:$minerListenPort',
      '--cpu-workers',
      cpuWorkers.toString(),
      '--gpu-devices',
      gpuDevices.toString(),
      '--metrics-port',
      _getMetricsPort().toString(),
    ];

    try {
      _externalMinerProcess = await Process.start(
        externalMinerBin.path,
        minerArgs,
      );
    } catch (e) {
      throw Exception('Failed to start external miner: $e');
    }

    // Set up external miner log handling
    _externalMinerProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final logEntry = LogEntry(
            message: line,
            timestamp: DateTime.now(),
            source: 'quantus-miner',
          );
          _logsController.add(logEntry);
          _log.d('[miner] $line');
        });

    _externalMinerProcess!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final logEntry = LogEntry(
            message: line,
            timestamp: DateTime.now(),
            source: line.isMinerError ? 'quantus-miner-error' : 'quantus-miner',
          );
          _logsController.add(logEntry);
          if (line.isMinerError) {
            _log.w('[miner] $line');
          } else {
            _log.d('[miner] $line');
          }
        });

    // Monitor external miner process exit
    _externalMinerProcess!.exitCode.then((exitCode) {
      if (exitCode != 0) {
        _log.w('External miner exited with code: $exitCode');
      }
    });

    // Give the external miner a moment to start up and connect
    await Future.delayed(const Duration(seconds: 2));

    // Check if external miner process is still alive
    bool minerStillRunning = true;
    try {
      final pid = _externalMinerProcess!.pid;
      minerStillRunning = await _isProcessRunning(pid);
    } catch (e) {
      minerStillRunning = false;
    }

    if (!minerStillRunning) {
      throw Exception('External miner process died during startup');
    }

    // Start external miner API polling (every second)
    _externalMinerApiClient.startPolling();

    // Start RPC polling now that everything is ready
    _chainRpcClient.startPolling();
  }

  void stop() {
    _log.i('Stopping mining processes...');
    _syncStatusTimer?.cancel();
    _externalMinerApiClient.stopPolling();
    _chainRpcClient.stopPolling();

    // Kill external miner process first
    if (_externalMinerProcess != null) {
      try {
        _log.d('Killing external miner (PID: ${_externalMinerProcess!.pid})');

        // Try graceful termination first
        _externalMinerProcess!.kill(ProcessSignal.sigterm);

        // Wait briefly for graceful shutdown
        Future.delayed(MinerConfig.gracefulShutdownTimeout).then((_) async {
          // Check if process is still running and force kill if necessary
          try {
            if (await _isProcessRunning(_externalMinerProcess!.pid)) {
              _log.d('External miner still running, force killing...');
              _externalMinerProcess!.kill(ProcessSignal.sigkill);
            }
          } catch (e) {
            // Process is already dead, which is what we want
            _log.d('External miner already terminated');
          }
        });
      } catch (e) {
        _log.e('Error killing external miner', error: e);
        // Try force kill as backup
        try {
          _externalMinerProcess!.kill(ProcessSignal.sigkill);
        } catch (e2) {
          _log.e('Error force killing external miner', error: e2);
        }
      }
    }

    // Kill node process
    try {
      _log.d('Killing node process (PID: ${_nodeProcess.pid})');

      // Try graceful termination first
      _nodeProcess.kill(ProcessSignal.sigterm);

      // Wait briefly for graceful shutdown
      Future.delayed(MinerConfig.gracefulShutdownTimeout).then((_) async {
        // Check if process is still running and force kill if necessary
        try {
          if (await _isProcessRunning(_nodeProcess.pid)) {
            _log.d('Node still running, force killing...');
            _nodeProcess.kill(ProcessSignal.sigkill);
          }
        } catch (e) {
          // Process is already dead, which is what we want
          _log.d('Node already terminated');
        }
      });
    } catch (e) {
      _log.e('Error killing node process', error: e);
      // Try force kill as backup
      try {
        _nodeProcess.kill(ProcessSignal.sigkill);
      } catch (e2) {
        _log.e('Error force killing node process', error: e2);
      }
    }

    // Close the logs stream
    if (!_logsController.isClosed) {
      _logsController.close();
    }
  }

  /// Force stop both processes immediately with SIGKILL
  void forceStop() {
    _log.i('Force stopping all processes...');
    _syncStatusTimer?.cancel();

    final List<Future<void>> killFutures = [];

    // Force kill external miner
    if (_externalMinerProcess != null) {
      final minerPid = _externalMinerProcess!.pid;
      killFutures.add(_forceKillProcess(minerPid, 'external miner'));
      try {
        _externalMinerProcess!.kill(ProcessSignal.sigkill);
      } catch (e) {
        _log.e('Error force killing external miner', error: e);
      }
      _externalMinerProcess = null;
    }

    // Force kill node process
    try {
      final nodePid = _nodeProcess.pid;
      killFutures.add(_forceKillProcess(nodePid, 'node'));
      _nodeProcess.kill(ProcessSignal.sigkill);
    } catch (e) {
      _log.e('Error force killing node', error: e);
    }

    // Wait for all kills to complete (with timeout)
    Future.wait(killFutures).timeout(
      MinerConfig.forceKillTimeout,
      onTimeout: () {
        _log.w('Force kill operations timed out');
        return [];
      },
    );

    // Close the logs stream
    if (!_logsController.isClosed) {
      _logsController.close();
    }
  }

  /// Check if a process with the given PID is running.
  /// Delegates to ProcessCleanupService.
  Future<bool> _isProcessRunning(int pid) async {
    return ProcessCleanupService.isProcessRunning(pid);
  }

  /// Helper method to force kill a process by PID with verification.
  /// Delegates to ProcessCleanupService.
  Future<void> _forceKillProcess(int pid, String processName) async {
    await ProcessCleanupService.forceKillProcess(pid, processName);
  }

  /// Handle external miner metrics updates
  void _handleExternalMinerMetrics(ExternalMinerMetrics metrics) {
    if (metrics.isHealthy && metrics.hashRate > 0) {
      // Valid metrics received
      _lastValidHashrate = metrics.hashRate;
      _consecutiveMetricsFailures = 0;

      _statsService.updateHashrate(metrics.hashRate);

      // Update workers count from external miner if available
      if (metrics.workers > 0) {
        _statsService.updateWorkers(metrics.workers);
      }

      // Update CPU capacity from external miner if available
      if (metrics.cpuCapacity > 0) {
        _statsService.updateCpuCapacity(metrics.cpuCapacity);
      }

      // Update GPU devices count from external miner if available
      if (metrics.gpuDevices > 0) {
        _statsService.updateGpuDevices(metrics.gpuDevices);
      }

      onStatsUpdate?.call(_statsService.currentStats);
    } else if (metrics.hashRate == 0.0 && _lastValidHashrate > 0) {
      // Received 0.0 but we have a valid hashrate - ignore it and keep the last valid one
      _statsService.updateHashrate(_lastValidHashrate);
      onStatsUpdate?.call(_statsService.currentStats);
    } else {
      // Invalid or zero metrics
      _consecutiveMetricsFailures++;

      // Only reset to zero after multiple consecutive failures
      if (_consecutiveMetricsFailures >=
          MinerConfig.maxConsecutiveMetricsFailures) {
        _statsService.updateHashrate(0.0);
        _lastValidHashrate = 0.0;
        onStatsUpdate?.call(_statsService.currentStats);
      } else {
        // Keep the last valid hashrate during temporary issues
        if (_lastValidHashrate > 0) {
          _statsService.updateHashrate(_lastValidHashrate);
          onStatsUpdate?.call(_statsService.currentStats);
        }
      }
    }
  }

  /// Handle external miner API errors
  void _handleExternalMinerError(String error) {
    _consecutiveMetricsFailures++;

    // Only reset hashrate after multiple consecutive errors
    if (_consecutiveMetricsFailures >=
        MinerConfig.maxConsecutiveMetricsFailures) {
      if (_statsService.currentStats.hashrate != 0.0) {
        _statsService.updateHashrate(0.0);
        _lastValidHashrate = 0.0;
        onStatsUpdate?.call(_statsService.currentStats);
      }
    }
  }

  /// Check if required ports are available and cleanup if needed
  Future<void> _ensurePortsAvailable() async {
    final ports = await ProcessCleanupService.ensurePortsAvailable(
      quicPort: minerListenPort,
      metricsPort: MinerConfig.defaultMinerMetricsPort,
    );

    // If metrics port changed, update the API client
    final actualMetricsPort = ports['metrics']!;
    if (actualMetricsPort != MinerConfig.defaultMinerMetricsPort) {
      _externalMinerApiClient = ExternalMinerApiClient(
        metricsUrl: MinerConfig.minerMetricsUrl(actualMetricsPort),
      );
      _externalMinerApiClient.onMetricsUpdate = _handleExternalMinerMetrics;
      _externalMinerApiClient.onError = _handleExternalMinerError;
    }

    // Store the metrics port for later use
    _actualMetricsPort = actualMetricsPort;
  }

  // Track the actual metrics port being used (may differ from default)
  int _actualMetricsPort = MinerConfig.defaultMinerMetricsPort;

  /// Get the metrics port to use (determined during _ensurePortsAvailable)
  int _getMetricsPort() {
    return _actualMetricsPort;
  }

  /// Wait for the node RPC to be ready (blocking)
  /// Used to ensure node is ready before starting miner
  Future<void> _waitForNodeRpcReady() async {
    _log.d('Waiting for node RPC to be ready...');

    // Try to connect to RPC endpoint with exponential backoff
    int attempts = 0;
    Duration delay = MinerConfig.rpcInitialRetryDelay;

    while (attempts < MinerConfig.maxRpcRetries) {
      try {
        final isReady = await _chainRpcClient.isReachable();
        if (isReady) {
          _log.i('Node RPC is ready');
          return;
        }
      } catch (e) {
        // Expected during startup
      }

      attempts++;
      _log.d(
        'Node RPC not ready (attempt $attempts/${MinerConfig.maxRpcRetries}), waiting ${delay.inSeconds}s...',
      );

      await Future.delayed(delay);

      // Exponential backoff, but cap at max retry delay
      if (delay < MinerConfig.rpcMaxRetryDelay) {
        delay = Duration(seconds: (delay.inSeconds * 1.5).round());
        if (delay > MinerConfig.rpcMaxRetryDelay) {
          delay = MinerConfig.rpcMaxRetryDelay;
        }
      }
    }

    _log.w(
      'Node RPC not ready after ${MinerConfig.maxRpcRetries} attempts, proceeding anyway...',
    );
  }

  void _handleChainInfoUpdate(ChainInfo info) {
    _log.d('Chain info: peers=${info.peerCount}, block=${info.currentBlock}');

    // Update peer count from RPC (most accurate)
    if (info.peerCount >= 0) {
      _statsService.updatePeerCount(info.peerCount);
    }

    // Update chain name from RPC
    _statsService.updateChainName(info.chainName);

    // Always update current block and target block from RPC (most authoritative)
    _statsService.setSyncingState(
      info.isSyncing,
      info.currentBlock,
      info.targetBlock ?? info.currentBlock,
    );

    onStatsUpdate?.call(_statsService.currentStats);
  }

  /// Handle chain RPC errors
  void _handleChainRpcError(String error) {
    // Only log significant RPC errors, not connection issues during startup
    if (!error.contains('Connection refused') && !error.contains('timeout')) {
      _log.w('Chain RPC error: $error');
    }
  }

  /// Dispose of resources
  void dispose() {
    _syncStatusTimer?.cancel();
    _externalMinerApiClient.dispose();
    _chainRpcClient.dispose();
  }
}
