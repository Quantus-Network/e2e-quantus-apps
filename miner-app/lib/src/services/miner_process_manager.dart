import 'dart:async';
import 'dart:io';

import 'package:quantus_miner/src/config/miner_config.dart';
import 'package:quantus_miner/src/models/miner_error.dart';
import 'package:quantus_miner/src/services/log_stream_processor.dart';
import 'package:quantus_miner/src/services/process_cleanup_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';

final _log = log.withTag('ExternalMiner');

/// Configuration for starting the external miner process.
class ExternalMinerConfig {
  /// Path to the miner binary.
  final File binary;

  /// Address and port of the node's QUIC endpoint (e.g., "127.0.0.1:9833").
  final String nodeAddress;

  /// Number of CPU worker threads.
  final int cpuWorkers;

  /// Number of GPU devices to use.
  final int gpuDevices;

  /// Port for the miner's Prometheus metrics endpoint.
  final int metricsPort;

  ExternalMinerConfig({
    required this.binary,
    required this.nodeAddress,
    this.cpuWorkers = 8,
    this.gpuDevices = 0,
    this.metricsPort = 9900,
  });
}

/// Manages the quantus-miner (external miner) process lifecycle.
///
/// Responsibilities:
/// - Starting the miner process with proper arguments
/// - Monitoring process health and exit
/// - Stopping the process gracefully or forcefully
/// - Emitting log entries and error events
class MinerProcessManager {
  Process? _process;
  late LogStreamProcessor _logProcessor;
  final _errorController = StreamController<MinerError>.broadcast();

  bool _intentionalStop = false;

  /// Stream of log entries from the miner.
  Stream<LogEntry> get logs => _logProcessor.logs;

  /// Stream of errors (crashes, startup failures).
  Stream<MinerError> get errors => _errorController.stream;

  /// The process ID, or null if not running.
  int? get pid => _process?.pid;

  /// Whether the miner process is currently running.
  bool get isRunning => _process != null;

  MinerProcessManager() {
    _logProcessor = LogStreamProcessor(sourceName: 'miner');
  }

  /// Start the miner process.
  ///
  /// Throws an exception if startup fails.
  Future<void> start(ExternalMinerConfig config) async {
    if (_process != null) {
      _log.w('Miner already running (PID: ${_process!.pid})');
      return;
    }

    _intentionalStop = false;

    // Validate binary exists
    if (!await config.binary.exists()) {
      final error = MinerError.minerStartupFailed(
        'Miner binary not found: ${config.binary.path}',
      );
      _errorController.add(error);
      throw Exception(error.message);
    }

    // Build command arguments
    final args = _buildArgs(config);

    _log.i('Starting miner...');
    _log.d('Command: ${config.binary.path} ${args.join(' ')}');

    try {
      _process = await Process.start(config.binary.path, args);
      _logProcessor.attach(_process!);

      // Monitor for unexpected exit
      _process!.exitCode.then(_handleExit);

      // Verify it started successfully by waiting briefly
      await Future.delayed(const Duration(seconds: 2));

      if (_process != null) {
        final stillRunning = await ProcessCleanupService.isProcessRunning(
          _process!.pid,
        );
        if (!stillRunning) {
          final error = MinerError.minerStartupFailed(
            'Miner died during startup',
          );
          _errorController.add(error);
          _process = null;
          throw Exception(error.message);
        }
      }

      _log.i('Miner started (PID: ${_process!.pid})');
    } catch (e, st) {
      if (e.toString().contains('Miner died during startup')) {
        rethrow;
      }
      final error = MinerError.minerStartupFailed(e, st);
      _errorController.add(error);
      _process = null;
      rethrow;
    }
  }

  /// Stop the miner process gracefully.
  ///
  /// Returns a Future that completes when the process has stopped.
  Future<void> stop() async {
    if (_process == null) {
      return;
    }

    _intentionalStop = true;
    final processPid = _process!.pid;
    _log.i('Stopping miner (PID: $processPid)...');

    // Try graceful termination first
    _process!.kill(ProcessSignal.sigterm);

    // Wait for graceful shutdown
    final exited = await _waitForExit(MinerConfig.gracefulShutdownTimeout);

    if (!exited) {
      // Force kill if still running
      _log.d('Miner still running, force killing...');
      await _forceKill();
    }

    _cleanup();
    _log.i('Miner stopped');
  }

  /// Force stop the miner process immediately.
  void forceStop() {
    if (_process == null) {
      return;
    }

    _intentionalStop = true;
    final processPid = _process!.pid;
    _log.i('Force stopping miner (PID: $processPid)...');

    try {
      _process!.kill(ProcessSignal.sigkill);
    } catch (e) {
      _log.e('Error force killing miner', error: e);
    }

    // Also use system cleanup as backup
    ProcessCleanupService.forceKillProcess(processPid, 'miner');

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

  List<String> _buildArgs(ExternalMinerConfig config) {
    return [
      'serve', // Subcommand required by new miner CLI
      '--node-addr',
      config.nodeAddress,
      '--cpu-workers',
      config.cpuWorkers.toString(),
      '--gpu-devices',
      config.gpuDevices.toString(),
      '--metrics-port',
      config.metricsPort.toString(),
    ];
  }

  void _handleExit(int exitCode) {
    if (_intentionalStop) {
      _log.d('Miner exited (code: $exitCode) - intentional stop');
    } else {
      _log.w('Miner crashed (exit code: $exitCode)');
      _errorController.add(MinerError.minerCrashed(exitCode));
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
