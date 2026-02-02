import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quantus_miner/src/config/miner_config.dart';
import 'package:quantus_miner/src/models/miner_error.dart';
import 'package:quantus_miner/src/services/binary_manager.dart';
import 'package:quantus_miner/src/services/log_stream_processor.dart';
import 'package:quantus_miner/src/services/process_cleanup_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';

final _log = log.withTag('NodeProcess');

/// Configuration for starting the node process.
class NodeConfig {
  /// Path to the node binary.
  final File binary;

  /// Path to the node identity key file.
  final File identityFile;

  /// The rewards address for mining.
  final String rewardsAddress;

  /// Chain ID to connect to ('dev' or 'dirac').
  final String chainId;

  /// Port for the QUIC miner connection.
  final int minerListenPort;

  /// Port for JSON-RPC endpoint.
  final int rpcPort;

  /// Port for Prometheus metrics.
  final int prometheusPort;

  /// Port for P2P networking.
  final int p2pPort;

  NodeConfig({
    required this.binary,
    required this.identityFile,
    required this.rewardsAddress,
    this.chainId = 'dev',
    this.minerListenPort = 9833,
    this.rpcPort = 9933,
    this.prometheusPort = 9616,
    this.p2pPort = 30333,
  });
}

/// Manages the quantus-node process lifecycle.
///
/// Responsibilities:
/// - Starting the node process with proper arguments
/// - Monitoring process health and exit
/// - Stopping the process gracefully or forcefully
/// - Emitting log entries and error events
class NodeProcessManager {
  Process? _process;
  late LogStreamProcessor _logProcessor;
  final _errorController = StreamController<MinerError>.broadcast();

  bool _intentionalStop = false;

  /// Stream of log entries from the node.
  Stream<LogEntry> get logs => _logProcessor.logs;

  /// Stream of errors (crashes, startup failures).
  Stream<MinerError> get errors => _errorController.stream;

  /// The process ID, or null if not running.
  int? get pid => _process?.pid;

  /// Whether the node process is currently running.
  bool get isRunning => _process != null;

  /// Callback to get current sync state for log filtering.
  SyncStateProvider? getSyncState;

  NodeProcessManager() {
    _logProcessor = LogStreamProcessor(
      sourceName: 'node',
      getSyncState: () => getSyncState?.call() ?? false,
    );
  }

  /// Start the node process.
  ///
  /// Throws an exception if startup fails.
  Future<void> start(NodeConfig config) async {
    if (_process != null) {
      _log.w('Node already running (PID: ${_process!.pid})');
      return;
    }

    _intentionalStop = false;

    // Validate binary exists
    if (!await config.binary.exists()) {
      final error = MinerError.nodeStartupFailed(
        'Node binary not found: ${config.binary.path}',
      );
      _errorController.add(error);
      throw Exception(error.message);
    }

    // Validate identity file exists
    if (!await config.identityFile.exists()) {
      final error = MinerError.nodeStartupFailed(
        'Identity file not found: ${config.identityFile.path}',
      );
      _errorController.add(error);
      throw Exception(error.message);
    }

    // Prepare data directory
    final quantusHome = await BinaryManager.getQuantusHomeDirectoryPath();
    final basePath = p.join(quantusHome, 'node_data');
    await Directory(basePath).create(recursive: true);

    // Build command arguments
    final args = _buildArgs(config, basePath);

    _log.i('Starting node...');
    _log.d('Command: ${config.binary.path} ${args.join(' ')}');

    try {
      _process = await Process.start(config.binary.path, args);
      _logProcessor.attach(_process!);

      // Monitor for unexpected exit
      _process!.exitCode.then(_handleExit);

      _log.i('Node started (PID: ${_process!.pid})');
    } catch (e, st) {
      final error = MinerError.nodeStartupFailed(e, st);
      _errorController.add(error);
      _process = null;
      rethrow;
    }
  }

  /// Stop the node process gracefully.
  ///
  /// Returns a Future that completes when the process has stopped.
  Future<void> stop() async {
    if (_process == null) {
      return;
    }

    _intentionalStop = true;
    final processPid = _process!.pid;
    _log.i('Stopping node (PID: $processPid)...');

    // Try graceful termination first
    _process!.kill(ProcessSignal.sigterm);

    // Wait for graceful shutdown
    final exited = await _waitForExit(MinerConfig.gracefulShutdownTimeout);

    if (!exited) {
      // Force kill if still running
      _log.d('Node still running, force killing...');
      await _forceKill();
    }

    _cleanup();
    _log.i('Node stopped');
  }

  /// Force stop the node process immediately.
  void forceStop() {
    if (_process == null) {
      return;
    }

    _intentionalStop = true;
    final processPid = _process!.pid;
    _log.i('Force stopping node (PID: $processPid)...');

    try {
      _process!.kill(ProcessSignal.sigkill);
    } catch (e) {
      _log.e('Error force killing node', error: e);
    }

    // Also use system cleanup as backup
    ProcessCleanupService.forceKillProcess(processPid, 'node');

    _cleanup();
  }

  /// Dispose of all resources.
  void dispose() {
    forceStop();
    _logProcessor.dispose();
    if (!_errorController.isClosed) {
      _errorController.close();
    }
  }

  List<String> _buildArgs(NodeConfig config, String basePath) {
    return [
      '--base-path', basePath,
      '--node-key-file', config.identityFile.path,
      '--rewards-address', config.rewardsAddress,
      '--validator',
      // Chain selection
      if (config.chainId == 'dev') '--dev' else ...['--chain', config.chainId],
      '--port', config.p2pPort.toString(),
      '--prometheus-port', config.prometheusPort.toString(),
      '--experimental-rpc-endpoint',
      'listen-addr=${MinerConfig.localhost}:${config.rpcPort},methods=unsafe,cors=all',
      '--name', 'QuantusMinerGUI',
      '--miner-listen-port', config.minerListenPort.toString(),
      '--enable-peer-sharing',
    ];
  }

  void _handleExit(int exitCode) {
    if (_intentionalStop) {
      _log.d('Node exited (code: $exitCode) - intentional stop');
    } else {
      _log.w('Node crashed (exit code: $exitCode)');
      _errorController.add(MinerError.nodeCrashed(exitCode));
    }
    _cleanup();
  }

  Future<bool> _waitForExit(Duration timeout) async {
    if (_process == null) return true;

    try {
      await _process!.exitCode.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _forceKill() async {
    if (_process == null) return;

    try {
      _process!.kill(ProcessSignal.sigkill);
      await _process!.exitCode.timeout(
        MinerConfig.processVerificationDelay,
        onTimeout: () => -1,
      );
    } catch (e) {
      _log.e('Error during force kill', error: e);
    }
  }

  void _cleanup() {
    _logProcessor.detach();
    _process = null;
  }
}
