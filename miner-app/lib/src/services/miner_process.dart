import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import './mining_stats_service.dart';
import './hashrate_estimator.dart';
import './prometheus_service.dart';

import './binary_manager.dart';
import './log_filter_service.dart';

class LogEntry {
  final String message;
  final DateTime timestamp;
  final String source; // 'node', 'quantus-miner', 'error'

  LogEntry({required this.message, required this.timestamp, required this.source});

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
  late HashrateEstimator _hashrateEstimator;
  late PrometheusService _prometheusService;

  Timer? _syncStatusTimer;
  double? _currentHashrate;
  final int minerCores;

  double? get currentHashrate => _currentHashrate;
  final int externalMinerPort;

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
    this.minerCores = 8,
    this.externalMinerPort = 9833,
  });

  Future<void> start() async {
    // First, ensure both binaries are available
    print('DEBUG: Ensuring node binary is available...');
    await BinaryManager.ensureNodeBinary();

    print('DEBUG: Ensuring external miner binary is available...');
    final externalMinerBinPath = await BinaryManager.getExternalMinerBinaryFilePath();
    print('DEBUG: External miner expected at: $externalMinerBinPath');

    await BinaryManager.ensureExternalMinerBinary();
    final externalMinerBin = File(externalMinerBinPath);

    print('DEBUG: Checking if external miner binary exists after ensure...');
    if (!await externalMinerBin.exists()) {
      print('DEBUG: ERROR - External miner binary not found at $externalMinerBinPath');
      throw Exception('External miner binary not found at $externalMinerBinPath');
    } else {
      print('DEBUG: External miner binary found at $externalMinerBinPath');

      // Check if it's executable
      final stat = await externalMinerBin.stat();
      print('DEBUG: External miner binary permissions: ${stat.mode.toRadixString(8)}');
    }

    // Start the external miner first
    print('DEBUG: Starting external miner on port $externalMinerPort with $minerCores cores...');
    print('DEBUG: External miner command: ${externalMinerBin.path} --port $externalMinerPort --workers $minerCores');

    try {
      _externalMinerProcess = await Process.start(externalMinerBin.path, [
        '--port',
        externalMinerPort.toString(),
        '--workers',
        minerCores.toString(),
      ]);
      print('DEBUG: External miner process started successfully with PID: ${_externalMinerProcess!.pid}');
    } catch (e) {
      print('DEBUG: ERROR - Failed to start external miner process: $e');
      throw Exception('Failed to start external miner: $e');
    }

    // Set up external miner log handling
    _externalMinerProcess!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      final logEntry = LogEntry(message: line, timestamp: DateTime.now(), source: 'quantus-miner');
      _logsController.add(logEntry);
      print('[ext-miner] $line');
    });

    _externalMinerProcess!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      final logEntry = LogEntry(message: line, timestamp: DateTime.now(), source: 'quantus-miner-error');
      _logsController.add(logEntry);
      print('[ext-miner-err] $line');
    });

    // Monitor external miner process exit
    _externalMinerProcess!.exitCode.then((exitCode) {
      print('DEBUG: External miner process exited with code: $exitCode');
      if (exitCode != 0) {
        print('DEBUG: External miner crashed! Exit code: $exitCode');
        // Convert exit code to signal name if it's negative
        if (exitCode < 0) {
          final signal = -exitCode;
          print('DEBUG: External miner was killed by signal: $signal');
          // Common signals: 2=SIGINT, 9=SIGKILL, 15=SIGTERM, 30=SIGUSR1
          switch (signal) {
            case 2:
              print('DEBUG: Signal was SIGINT (interrupt)');
              break;
            case 9:
              print('DEBUG: Signal was SIGKILL (force kill)');
              break;
            case 15:
              print('DEBUG: Signal was SIGTERM (termination)');
              break;
            case 30:
              print('DEBUG: Signal was SIGUSR1 (user signal 1)');
              break;
            default:
              print('DEBUG: Unknown signal: $signal');
          }
        }
      }
    });

    // Give the external miner a moment to start up
    print('DEBUG: Waiting 3 seconds for external miner to start up...');
    await Future.delayed(const Duration(seconds: 3));

    // Check if external miner process is still alive
    bool minerStillRunning = true;
    try {
      // Check if the process has exited by looking at its PID
      final pid = _externalMinerProcess!.pid;
      final result = await Process.run('kill', ['-0', pid.toString()]);
      if (result.exitCode != 0) {
        print('DEBUG: External miner process (PID: $pid) is not running');
        minerStillRunning = false;
      } else {
        print('DEBUG: External miner process (PID: $pid) is still running');
      }
    } catch (e) {
      print('DEBUG: Error checking external miner process: $e');
      minerStillRunning = false;
    }

    if (!minerStillRunning) {
      throw Exception('External miner process died during startup');
    }

    // Test if external miner is responding on the port
    print('DEBUG: Testing if external miner is responding on port $externalMinerPort...');
    try {
      final testClient = HttpClient();
      testClient.connectionTimeout = const Duration(seconds: 5);
      final request = await testClient.getUrl(Uri.parse('http://127.0.0.1:$externalMinerPort'));
      final response = await request.close();
      print('DEBUG: External miner test response status: ${response.statusCode}');
      await response.drain(); // Consume the response
      testClient.close();
      print('DEBUG: External miner is responding correctly!');
    } catch (e) {
      print('DEBUG: External miner not responding on port $externalMinerPort: $e');
      print('DEBUG: This might be normal if the miner is still starting up');
    }

    // Now start the node process
    print('DEBUG: Starting node process...');
    final quantusHome = await BinaryManager.getQuantusHomeDirectoryPath();
    final basePath = p.join(quantusHome, 'node_data');
    await Directory(basePath).create(recursive: true);

    final nodeKeyFileFromFileSystem = await BinaryManager.getNodeKeyFile();
    if (await nodeKeyFileFromFileSystem.exists()) {
      final stat = await nodeKeyFileFromFileSystem.stat();
      print('DEBUG: nodeKeyFileFromFileSystem (${nodeKeyFileFromFileSystem.path}) exists (size: ${stat.size} bytes)');
    } else {
      print('DEBUG: nodeKeyFileFromFileSystem (${nodeKeyFileFromFileSystem.path}) does not exist.');
    }

    if (await identityPath.exists()) {
      final stat = await identityPath.stat();
      print('DEBUG: identityPath file (${identityPath.path}) exists (size: ${stat.size} bytes)');
    } else {
      print('DEBUG: identityPath file (${identityPath.path}) to be used by node does not exist.');
    }

    // Read the rewards address from the file
    String rewardsAddress;
    try {
      if (!await rewardsPath.exists()) {
        throw Exception('Rewards address file not found: ${rewardsPath.path}');
      }
      rewardsAddress = await rewardsPath.readAsString();
      rewardsAddress = rewardsAddress.trim(); // Remove any whitespace/newlines
      print('DEBUG: Read rewards address from file: $rewardsAddress');
    } catch (e) {
      throw Exception('Failed to read rewards address from file ${rewardsPath.path}: $e');
    }

    final List<String> args = [
      '--base-path',
      basePath,
      '--node-key-file',
      identityPath.path,
      '--rewards-address',
      rewardsAddress,
      '--validator',
      '--chain',
      'schrodinger',
      '--port',
      '30333',
      '--prometheus-port',
      '9616',
      '--name',
      'QuantusMinerGUI',
      '--external-miner-url',
      'http://127.0.0.1:$externalMinerPort',
      '--enable-peer-sharing',
    ];

    print('DEBUG: Executing command:\n ${bin.path} ${args.join(' ')}');
    print('DEBUG: Args: ${args.join('\n')}');

    _nodeProcess = await Process.start(bin.path, args);
    _stdoutFilter = LogFilterService();
    _stderrFilter = LogFilterService();
    _statsService = MiningStatsService();
    _hashrateEstimator = HashrateEstimator();
    _prometheusService = PrometheusService();

    _stdoutFilter.reset();
    _stderrFilter.reset();
    _currentHashrate = null;

    Future<void> syncStatsWithPrometheous() async {
      try {
        final metrics = await _prometheusService.fetchMetrics();
        if (metrics == null || metrics.targetBlock == null) return;

        print('PROMETHEUS TARGET: ${metrics.targetBlock}');

        // Update target block from Prometheus
        _statsService.updateTargetBlock(metrics.targetBlock!);

        // Emit updated stats
        onStatsUpdate?.call(_statsService.currentStats);

        _syncStatusTimer?.cancel();
      } catch (e) {
        print('Failed to fetch Prometheus metrics: $e');
      }
    }

    // Start Prometheus polling for target block (every 3 seconds)
    _syncStatusTimer?.cancel();
    _syncStatusTimer = Timer.periodic(const Duration(seconds: 3), (timer) => syncStatsWithPrometheous());

    // Process each log line
    void processLogLine(String line, String streamType) {
      final statsUpdated = _statsService.parseLogLine(line);

      final hashrate = _hashrateEstimator.updateAndEstimate(line);
      if (hashrate != null) {
        _statsService.updateHashrate(hashrate);
      }

      if (statsUpdated || hashrate != null) {
        onStatsUpdate?.call(_statsService.currentStats);
      }

      bool shouldPrint;
      if (streamType == 'stdout') {
        shouldPrint = _stdoutFilter.shouldPrintLine(line, isNodeSyncing: _statsService.currentStats.isSyncing);
      } else {
        shouldPrint = _stderrFilter.shouldPrintLine(line, isNodeSyncing: _statsService.currentStats.isSyncing);
      }

      if (shouldPrint) {
        String source;
        final lowerLine = line.toLowerCase();

        if (lowerLine.contains('error') ||
            lowerLine.contains('panic') ||
            lowerLine.contains('fatal') ||
            lowerLine.contains('critical') ||
            lowerLine.contains('failed') ||
            lowerLine.contains('warn')) {
          source = 'node-error';
        } else if (streamType == 'stdout') {
          source = 'node';
        } else {
          source = 'node';
        }

        final logEntry = LogEntry(message: line, timestamp: DateTime.now(), source: source);
        _logsController.add(logEntry);
        print(source == 'node' ? '[node] $line' : '[node-error] $line');
      }
    }

    _nodeProcess.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      processLogLine(line, 'stdout');
    });

    _nodeProcess.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      processLogLine(line, 'stderr');
    });
  }

  void stop() {
    print('MinerProcess: stop() called. Killing processes.');
    _syncStatusTimer?.cancel();
    _currentHashrate = null;

    // Kill external miner process first
    if (_externalMinerProcess != null) {
      try {
        print('MinerProcess: Attempting to kill external miner process (PID: ${_externalMinerProcess!.pid})');

        // Try graceful termination first
        _externalMinerProcess!.kill(ProcessSignal.sigterm);

        // Wait briefly for graceful shutdown
        Future.delayed(const Duration(seconds: 2)).then((_) async {
          // Check if process is still running and force kill if necessary
          try {
            final result = await Process.run('kill', ['-0', _externalMinerProcess!.pid.toString()]);
            if (result.exitCode == 0) {
              print('MinerProcess: External miner still running, force killing...');
              _externalMinerProcess!.kill(ProcessSignal.sigkill);
            }
          } catch (e) {
            // Process is already dead, which is what we want
            print('MinerProcess: External miner process already terminated');
          }
        });
      } catch (e) {
        print('MinerProcess: Error killing external miner process: $e');
        // Try force kill as backup
        try {
          _externalMinerProcess!.kill(ProcessSignal.sigkill);
        } catch (e2) {
          print('MinerProcess: Error force killing external miner process: $e2');
        }
      }
    }

    // Kill node process
    try {
      print('MinerProcess: Attempting to kill node process (PID: ${_nodeProcess.pid})');

      // Try graceful termination first
      _nodeProcess.kill(ProcessSignal.sigterm);

      // Wait briefly for graceful shutdown
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        // Check if process is still running and force kill if necessary
        try {
          final result = await Process.run('kill', ['-0', _nodeProcess.pid.toString()]);
          if (result.exitCode == 0) {
            print('MinerProcess: Node process still running, force killing...');
            _nodeProcess.kill(ProcessSignal.sigkill);
          }
        } catch (e) {
          // Process is already dead, which is what we want
          print('MinerProcess: Node process already terminated');
        }
      });
    } catch (e) {
      print('MinerProcess: Error killing node process: $e');
      // Try force kill as backup
      try {
        _nodeProcess.kill(ProcessSignal.sigkill);
      } catch (e2) {
        print('MinerProcess: Error force killing node process: $e2');
      }
    }

    // Close the logs stream
    if (!_logsController.isClosed) {
      _logsController.close();
    }
  }

  /// Force stop both processes immediately with SIGKILL
  void forceStop() {
    print('MinerProcess: forceStop() called. Force killing processes.');
    _syncStatusTimer?.cancel();
    _currentHashrate = null;

    final List<Future<void>> killFutures = [];

    // Force kill external miner
    if (_externalMinerProcess != null) {
      final minerPid = _externalMinerProcess!.pid;
      killFutures.add(_forceKillProcess(minerPid, 'external miner'));
      try {
        _externalMinerProcess!.kill(ProcessSignal.sigkill);
      } catch (e) {
        print('MinerProcess: Error force killing external miner process: $e');
      }
      _externalMinerProcess = null;
    }

    // Force kill node process
    try {
      final nodePid = _nodeProcess.pid;
      killFutures.add(_forceKillProcess(nodePid, 'node'));
      _nodeProcess.kill(ProcessSignal.sigkill);
    } catch (e) {
      print('MinerProcess: Error force killing node process: $e');
    }

    // Wait for all kills to complete (with timeout)
    Future.wait(killFutures).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('MinerProcess: Force kill operations timed out');
        return [];
      },
    );

    // Close the logs stream
    if (!_logsController.isClosed) {
      _logsController.close();
    }
  }

  /// Helper method to force kill a process by PID with verification
  Future<void> _forceKillProcess(int pid, String processName) async {
    try {
      print('MinerProcess: Force killing $processName process (PID: $pid)');

      // First try SIGKILL via kill command for better reliability
      final killResult = await Process.run('kill', ['-9', pid.toString()]);

      if (killResult.exitCode == 0) {
        print('MinerProcess: Successfully force killed $processName (PID: $pid)');
      } else {
        print('MinerProcess: kill command failed for $processName (PID: $pid), exit code: ${killResult.exitCode}');
      }

      // Wait a moment then verify the process is dead
      await Future.delayed(const Duration(milliseconds: 500));

      final checkResult = await Process.run('kill', ['-0', pid.toString()]);
      if (checkResult.exitCode != 0) {
        print('MinerProcess: Verified $processName (PID: $pid) is terminated');
      } else {
        print('MinerProcess: WARNING - $processName (PID: $pid) may still be running');
        // Try pkill as last resort
        await Process.run('pkill', ['-9', '-f', processName.contains('miner') ? 'quantus-miner' : 'quantus-node']);
      }
    } catch (e) {
      print('MinerProcess: Error in _forceKillProcess for $processName: $e');
    }
  }
}
