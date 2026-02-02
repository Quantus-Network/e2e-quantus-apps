import 'dart:async';
import 'dart:io';

import 'package:quantus_miner/src/config/miner_config.dart';
import 'package:quantus_miner/src/models/miner_error.dart';
import 'package:quantus_miner/src/services/chain_rpc_client.dart';
import 'package:quantus_miner/src/services/external_miner_api_client.dart';
import 'package:quantus_miner/src/services/log_stream_processor.dart';
import 'package:quantus_miner/src/services/miner_process_manager.dart';
import 'package:quantus_miner/src/services/mining_stats_service.dart';
import 'package:quantus_miner/src/services/node_process_manager.dart';
import 'package:quantus_miner/src/services/process_cleanup_service.dart';
import 'package:quantus_miner/src/services/prometheus_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';

final _log = log.withTag('Orchestrator');

/// Current state of the mining orchestrator.
enum MiningState {
  /// Not started, ready to begin.
  idle,

  /// Node is starting up.
  startingNode,

  /// Node is running, waiting for RPC to be ready.
  waitingForRpc,

  /// Miner is starting up.
  startingMiner,

  /// Both node and miner are running, mining is active.
  mining,

  /// Currently stopping.
  stopping,

  /// An error occurred.
  error,
}

/// Configuration for starting a mining session.
class MiningSessionConfig {
  /// Path to the node binary.
  final File nodeBinary;

  /// Path to the miner binary.
  final File minerBinary;

  /// Path to the node identity key file.
  final File identityFile;

  /// Path to the rewards address file.
  final File rewardsFile;

  /// Chain ID to connect to.
  final String chainId;

  /// Number of CPU worker threads.
  final int cpuWorkers;

  /// Number of GPU devices to use.
  final int gpuDevices;

  /// Detected GPU count for stats.
  final int detectedGpuCount;

  /// Port for QUIC miner connection.
  final int minerListenPort;

  MiningSessionConfig({
    required this.nodeBinary,
    required this.minerBinary,
    required this.identityFile,
    required this.rewardsFile,
    this.chainId = 'dev',
    this.cpuWorkers = 8,
    this.gpuDevices = 0,
    this.detectedGpuCount = 0,
    this.minerListenPort = 9833,
  });
}

/// Orchestrates the complete mining workflow.
///
/// Coordinates:
/// - Node process lifecycle
/// - Miner process lifecycle
/// - Stats collection from multiple sources
/// - Error handling and crash detection
///
/// This is the main entry point for mining operations and replaces
/// the old monolithic MinerProcess class.
class MiningOrchestrator {
  // Process managers
  final NodeProcessManager _nodeManager = NodeProcessManager();
  final MinerProcessManager _minerManager = MinerProcessManager();

  // API clients for stats
  late ExternalMinerApiClient _minerApiClient;
  late PollingChainRpcClient _chainRpcClient;
  late PrometheusService _prometheusService;

  // Stats
  final MiningStatsService _statsService = MiningStatsService();

  // State
  MiningState _state = MiningState.idle;
  Timer? _prometheusTimer;
  int _actualMetricsPort = MinerConfig.defaultMinerMetricsPort;

  // Hashrate tracking for resilience
  double _lastValidHashrate = 0.0;
  int _consecutiveMetricsFailures = 0;

  // Stream controllers
  final _logsController = StreamController<LogEntry>.broadcast();
  final _statsController = StreamController<MiningStats>.broadcast();
  final _errorController = StreamController<MinerError>.broadcast();
  final _stateController = StreamController<MiningState>.broadcast();

  // Subscriptions
  StreamSubscription<LogEntry>? _nodeLogsSubscription;
  StreamSubscription<LogEntry>? _minerLogsSubscription;
  StreamSubscription<MinerError>? _nodeErrorSubscription;
  StreamSubscription<MinerError>? _minerErrorSubscription;

  // ============================================================
  // Public API
  // ============================================================

  /// Current mining state.
  MiningState get state => _state;

  /// Stream of log entries from both node and miner.
  Stream<LogEntry> get logsStream => _logsController.stream;

  /// Stream of mining statistics updates.
  Stream<MiningStats> get statsStream => _statsController.stream;

  /// Stream of errors (crashes, startup failures, etc.).
  Stream<MinerError> get errorStream => _errorController.stream;

  /// Stream of state changes.
  Stream<MiningState> get stateStream => _stateController.stream;

  /// Current mining statistics.
  MiningStats get currentStats => _statsService.currentStats;

  /// Whether mining is currently active.
  bool get isMining => _state == MiningState.mining;

  /// Whether the orchestrator is in any running state.
  bool get isRunning =>
      _state != MiningState.idle && _state != MiningState.error;

  /// Node process PID, if running.
  int? get nodeProcessPid => _nodeManager.pid;

  /// Miner process PID, if running.
  int? get minerProcessPid => _minerManager.pid;

  MiningOrchestrator() {
    _initializeApiClients();
    _setupNodeSyncCallback();
    _subscribeToProcessEvents();
  }

  /// Start mining with the given configuration.
  ///
  /// This will:
  /// 1. Cleanup any existing processes
  /// 2. Ensure ports are available
  /// 3. Start the node and wait for RPC
  /// 4. Start the miner
  /// 5. Begin polling for stats
  Future<void> start(MiningSessionConfig config) async {
    if (_state != MiningState.idle && _state != MiningState.error) {
      _log.w('Cannot start: already in state $_state');
      return;
    }

    try {
      // Initialize stats with worker counts
      _statsService.updateWorkers(config.cpuWorkers);
      _statsService.updateCpuCapacity(Platform.numberOfProcessors);
      _statsService.updateGpuDevices(config.gpuDevices);
      _statsService.updateGpuCapacity(config.detectedGpuCount);
      _emitStats();

      // Perform pre-start cleanup
      _setState(MiningState.startingNode);
      await ProcessCleanupService.performPreStartCleanup(config.chainId);

      // Ensure ports are available
      final ports = await ProcessCleanupService.ensurePortsAvailable(
        quicPort: config.minerListenPort,
        metricsPort: MinerConfig.defaultMinerMetricsPort,
      );
      _actualMetricsPort = ports['metrics']!;
      _updateMetricsClient();

      // Read rewards address
      final rewardsAddress = await _readRewardsAddress(config.rewardsFile);

      // Start node
      await _nodeManager.start(
        NodeConfig(
          binary: config.nodeBinary,
          identityFile: config.identityFile,
          rewardsAddress: rewardsAddress,
          chainId: config.chainId,
          minerListenPort: config.minerListenPort,
        ),
      );

      // Wait for node RPC to be ready
      _setState(MiningState.waitingForRpc);
      await _waitForNodeRpc();

      // Start miner
      _setState(MiningState.startingMiner);
      await _minerManager.start(
        ExternalMinerConfig(
          binary: config.minerBinary,
          nodeAddress: '${MinerConfig.localhost}:${config.minerListenPort}',
          cpuWorkers: config.cpuWorkers,
          gpuDevices: config.gpuDevices,
          metricsPort: _actualMetricsPort,
        ),
      );

      // Start polling
      _startPolling();

      _setState(MiningState.mining);
      _log.i('Mining started successfully');
    } catch (e, st) {
      _log.e('Failed to start mining', error: e, stackTrace: st);
      _setState(MiningState.error);
      await _stopInternal();
      rethrow;
    }
  }

  /// Stop mining gracefully.
  Future<void> stop() async {
    if (_state == MiningState.idle) {
      return;
    }

    _log.i('Stopping mining...');
    _setState(MiningState.stopping);
    await _stopInternal();
    _setState(MiningState.idle);
    _resetStats();
    _log.i('Mining stopped');
  }

  /// Force stop mining immediately.
  void forceStop() {
    _log.i('Force stopping mining...');
    _setState(MiningState.stopping);

    _stopPolling();
    _minerManager.forceStop();
    _nodeManager.forceStop();

    _setState(MiningState.idle);
    _resetStats();
    _log.i('Mining force stopped');
  }

  /// Dispose of all resources.
  void dispose() {
    forceStop();

    _nodeLogsSubscription?.cancel();
    _minerLogsSubscription?.cancel();
    _nodeErrorSubscription?.cancel();
    _minerErrorSubscription?.cancel();

    _nodeManager.dispose();
    _minerManager.dispose();
    _minerApiClient.dispose();
    _chainRpcClient.dispose();

    _logsController.close();
    _statsController.close();
    _errorController.close();
    _stateController.close();
  }

  // ============================================================
  // Internal Implementation
  // ============================================================

  void _initializeApiClients() {
    _minerApiClient = ExternalMinerApiClient(
      metricsUrl: MinerConfig.minerMetricsUrl(
        MinerConfig.defaultMinerMetricsPort,
      ),
    );
    _minerApiClient.onMetricsUpdate = _handleMinerMetrics;
    _minerApiClient.onError = _handleMinerMetricsError;

    _chainRpcClient = PollingChainRpcClient();
    _chainRpcClient.onChainInfoUpdate = _handleChainInfo;
    _chainRpcClient.onError = _handleChainRpcError;

    _prometheusService = PrometheusService();
  }

  void _setupNodeSyncCallback() {
    _nodeManager.getSyncState = () => _statsService.currentStats.isSyncing;
  }

  void _subscribeToProcessEvents() {
    // Forward node logs
    _nodeLogsSubscription = _nodeManager.logs.listen((entry) {
      _logsController.add(entry);
    });

    // Forward miner logs
    _minerLogsSubscription = _minerManager.logs.listen((entry) {
      _logsController.add(entry);
    });

    // Forward node errors
    _nodeErrorSubscription = _nodeManager.errors.listen((error) {
      _errorController.add(error);
      if (error.type == MinerErrorType.nodeCrashed &&
          _state == MiningState.mining) {
        _log.w('Node crashed while mining, stopping...');
        _handleCrash();
      }
    });

    // Forward miner errors
    _minerErrorSubscription = _minerManager.errors.listen((error) {
      _errorController.add(error);
      if (error.type == MinerErrorType.minerCrashed &&
          _state == MiningState.mining) {
        _log.w('Miner crashed while mining');
        // Don't stop everything - just emit the error for UI to show
      }
    });
  }

  void _updateMetricsClient() {
    if (_actualMetricsPort != MinerConfig.defaultMinerMetricsPort) {
      _minerApiClient = ExternalMinerApiClient(
        metricsUrl: MinerConfig.minerMetricsUrl(_actualMetricsPort),
      );
      _minerApiClient.onMetricsUpdate = _handleMinerMetrics;
      _minerApiClient.onError = _handleMinerMetricsError;
    }
  }

  Future<String> _readRewardsAddress(File rewardsFile) async {
    if (!await rewardsFile.exists()) {
      throw Exception('Rewards address file not found: ${rewardsFile.path}');
    }
    final address = await rewardsFile.readAsString();
    return address.trim();
  }

  Future<void> _waitForNodeRpc() async {
    _log.d('Waiting for node RPC...');
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
      _log.d('RPC not ready (attempt $attempts/${MinerConfig.maxRpcRetries})');
      await Future.delayed(delay);

      if (delay < MinerConfig.rpcMaxRetryDelay) {
        delay = Duration(seconds: (delay.inSeconds * 1.5).round());
        if (delay > MinerConfig.rpcMaxRetryDelay) {
          delay = MinerConfig.rpcMaxRetryDelay;
        }
      }
    }

    _log.w('Node RPC not ready after max attempts, proceeding anyway');
  }

  void _startPolling() {
    _minerApiClient.startPolling();
    _chainRpcClient.startPolling();

    // Prometheus polling for target block
    _prometheusTimer?.cancel();
    _prometheusTimer = Timer.periodic(
      MinerConfig.prometheusPollingInterval,
      (_) => _fetchPrometheusMetrics(),
    );
  }

  void _stopPolling() {
    _minerApiClient.stopPolling();
    _chainRpcClient.stopPolling();
    _prometheusTimer?.cancel();
    _prometheusTimer = null;
  }

  Future<void> _stopInternal() async {
    _stopPolling();

    // Stop miner first (depends on node)
    await _minerManager.stop();

    // Then stop node
    await _nodeManager.stop();
  }

  void _handleCrash() {
    _setState(MiningState.error);
    _stopPolling();
  }

  void _setState(MiningState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
      _log.d('State changed to: $newState');
    }
  }

  void _emitStats() {
    _statsController.add(_statsService.currentStats);
  }

  void _resetStats() {
    _statsService.updateHashrate(0);
    _lastValidHashrate = 0;
    _consecutiveMetricsFailures = 0;
    _emitStats();
  }

  // ============================================================
  // Metrics Handlers
  // ============================================================

  void _handleMinerMetrics(ExternalMinerMetrics metrics) {
    if (metrics.isHealthy && metrics.hashRate > 0) {
      _lastValidHashrate = metrics.hashRate;
      _consecutiveMetricsFailures = 0;

      _statsService.updateHashrate(metrics.hashRate);
      if (metrics.workers > 0) {
        _statsService.updateWorkers(metrics.workers);
      }
      if (metrics.cpuCapacity > 0) {
        _statsService.updateCpuCapacity(metrics.cpuCapacity);
      }
      if (metrics.gpuDevices > 0) {
        _statsService.updateGpuDevices(metrics.gpuDevices);
      }
      _emitStats();
    } else if (metrics.hashRate == 0.0 && _lastValidHashrate > 0) {
      // Keep last valid hashrate during temporary zeroes
      _statsService.updateHashrate(_lastValidHashrate);
      _emitStats();
    } else {
      _consecutiveMetricsFailures++;
      if (_consecutiveMetricsFailures >=
          MinerConfig.maxConsecutiveMetricsFailures) {
        _statsService.updateHashrate(0);
        _lastValidHashrate = 0;
        _emitStats();
      } else if (_lastValidHashrate > 0) {
        _statsService.updateHashrate(_lastValidHashrate);
        _emitStats();
      }
    }
  }

  void _handleMinerMetricsError(String error) {
    _consecutiveMetricsFailures++;
    if (_consecutiveMetricsFailures >=
        MinerConfig.maxConsecutiveMetricsFailures) {
      if (_statsService.currentStats.hashrate != 0) {
        _statsService.updateHashrate(0);
        _lastValidHashrate = 0;
        _emitStats();
      }
    }
  }

  void _handleChainInfo(ChainInfo info) {
    if (info.peerCount >= 0) {
      _statsService.updatePeerCount(info.peerCount);
    }
    _statsService.updateChainName(info.chainName);
    _statsService.setSyncingState(
      info.isSyncing,
      info.currentBlock,
      info.targetBlock ?? info.currentBlock,
    );
    _emitStats();
  }

  void _handleChainRpcError(String error) {
    if (!error.contains('Connection refused') && !error.contains('timeout')) {
      _log.w('Chain RPC error: $error');
    }
  }

  Future<void> _fetchPrometheusMetrics() async {
    try {
      final metrics = await _prometheusService.fetchMetrics();
      if (metrics?.targetBlock != null) {
        if (_statsService.currentStats.targetBlock < metrics!.targetBlock!) {
          _statsService.updateTargetBlock(metrics.targetBlock!);
          _emitStats();
        }
      }
    } catch (e) {
      _log.w('Failed to fetch Prometheus metrics', error: e);
    }
  }
}
