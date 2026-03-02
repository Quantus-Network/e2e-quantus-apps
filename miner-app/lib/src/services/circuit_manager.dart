import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:quantus_miner/src/services/binary_manager.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('CircuitManager');

/// Progress callback for circuit generation.
typedef CircuitProgressCallback = void Function(double progress, String message);

/// Information about circuit binary status.
class CircuitStatus {
  final bool isAvailable;
  final String? circuitDir;
  final int? totalSizeBytes;
  final String? version;

  /// Number of leaf proofs per aggregation batch (read from config.json)
  final int? numLeafProofs;

  const CircuitStatus({
    required this.isAvailable,
    this.circuitDir,
    this.totalSizeBytes,
    this.version,
    this.numLeafProofs,
  });

  static const unavailable = CircuitStatus(isAvailable: false);
}

/// Manages circuit binary files for ZK proof generation.
///
/// Circuit binaries (~163MB) are generated on first use via FFI to the
/// Rust circuit builder. This is a one-time operation that takes 10-30 minutes.
class CircuitManager {
  // Circuit files required for proof generation
  static const List<String> requiredFiles = [
    'prover.bin',
    'common.bin',
    'verifier.bin',
    'dummy_proof.bin',
    'aggregated_common.bin',
    'aggregated_verifier.bin',
    'config.json',
  ];

  // Default number of leaf proofs per aggregation (used only for circuit generation)
  // When using pre-built circuits, the actual value is read from config.json
  static const int defaultNumLeafProofs = 16;

  /// Get the directory where circuit files should be stored.
  static Future<String> getCircuitDirectory() async {
    final quantusHome = await BinaryManager.getQuantusHomeDirectoryPath();
    return path.join(quantusHome, 'circuits');
  }

  /// Check if circuit files are available.
  Future<CircuitStatus> checkStatus() async {
    try {
      final circuitDir = await getCircuitDirectory();
      final dir = Directory(circuitDir);

      if (!await dir.exists()) {
        return CircuitStatus.unavailable;
      }

      // Check all required files exist
      int totalSize = 0;
      for (final fileName in requiredFiles) {
        final file = File(path.join(circuitDir, fileName));
        if (!await file.exists()) {
          _log.d('Missing circuit file: $fileName');
          return CircuitStatus.unavailable;
        }
        totalSize += await file.length();
      }

      // Read config from config.json
      String? version;
      int? numLeafProofs;
      try {
        final configFile = File(path.join(circuitDir, 'config.json'));
        if (await configFile.exists()) {
          final content = await configFile.readAsString();
          final config = jsonDecode(content) as Map<String, dynamic>;
          version = config['version'] as String?;
          numLeafProofs = config['num_leaf_proofs'] as int?;
          _log.d('Circuit config: version=$version, numLeafProofs=$numLeafProofs');
        }
      } catch (e) {
        _log.w('Could not read circuit config', error: e);
      }

      return CircuitStatus(
        isAvailable: true,
        circuitDir: circuitDir,
        totalSizeBytes: totalSize,
        version: version,
        numLeafProofs: numLeafProofs,
      );
    } catch (e) {
      _log.e('Error checking circuit status', error: e);
      return CircuitStatus.unavailable;
    }
  }

  /// Generate circuit binaries using FFI to Rust.
  ///
  /// This is a **long-running operation** (10-30 minutes) that generates
  /// the ZK circuit binaries needed for wormhole withdrawal proofs.
  ///
  /// Note: The FFI call is async so it won't block the UI, but it runs
  /// in the main isolate (FFI doesn't support separate isolates without
  /// special setup).
  Future<bool> generateCircuits({CircuitProgressCallback? onProgress}) async {
    try {
      final circuitDir = await getCircuitDirectory();
      final dir = Directory(circuitDir);

      // Create directory if needed
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      onProgress?.call(0.0, 'Starting circuit generation...');
      _log.i('Starting circuit generation in $circuitDir (numLeafProofs=$defaultNumLeafProofs)');

      // Run the FFI call directly (it's async so won't block UI)
      _log.i('Calling FFI generateCircuitBinaries with outputDir=$circuitDir');
      final service = WormholeService();
      final result = await service.generateCircuitBinaries(outputDir: circuitDir, numLeafProofs: defaultNumLeafProofs);
      _log.i('FFI call returned: success=${result.success}, error=${result.error}, outputDir=${result.outputDir}');

      if (result.success) {
        _log.i('Circuit generation completed successfully');
        onProgress?.call(1.0, 'Circuit generation complete!');
        // Allow event loop to process UI updates
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } else {
        final error = result.error ?? 'Unknown error';
        onProgress?.call(0.0, 'Generation failed: $error');
        _log.e('Circuit generation failed: $error');
        // Clean up partial generation
        await deleteCircuits();
        return false;
      }
    } catch (e, st) {
      _log.e('Circuit generation failed with exception', error: e, stackTrace: st);
      onProgress?.call(0.0, 'Generation failed: $e');
      return false;
    }
  }

  /// Delete circuit files (e.g., for re-generation or cleanup).
  Future<void> deleteCircuits() async {
    try {
      final circuitDir = await getCircuitDirectory();
      final dir = Directory(circuitDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _log.i('Circuit files deleted');
      }
    } catch (e) {
      _log.e('Error deleting circuit files', error: e);
    }
  }

  /// Copy circuit files from a local source (for development/testing).
  Future<bool> copyFromLocal(String sourcePath, {CircuitProgressCallback? onProgress}) async {
    try {
      onProgress?.call(0.0, 'Copying circuit files...');

      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        _log.e('Source directory does not exist: $sourcePath');
        return false;
      }

      final circuitDir = await getCircuitDirectory();
      final destDir = Directory(circuitDir);

      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      int copied = 0;
      for (final fileName in requiredFiles) {
        final sourceFile = File(path.join(sourcePath, fileName));
        final destFile = File(path.join(circuitDir, fileName));

        if (!await sourceFile.exists()) {
          _log.e('Source file missing: $fileName');
          return false;
        }

        onProgress?.call(copied / requiredFiles.length, 'Copying $fileName...');

        await sourceFile.copy(destFile.path);
        copied++;
      }

      onProgress?.call(1.0, 'Copy complete!');
      _log.i('Circuit files copied from $sourcePath');
      return true;
    } catch (e) {
      _log.e('Error copying circuit files', error: e);
      return false;
    }
  }

  /// Get human-readable size string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
