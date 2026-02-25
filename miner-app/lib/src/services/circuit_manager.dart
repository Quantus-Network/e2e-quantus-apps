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

  const CircuitStatus({required this.isAvailable, this.circuitDir, this.totalSizeBytes, this.version});

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

  // Number of leaf proofs per aggregation (must match chain config)
  static const int numLeafProofs = 8;

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

      // Read version from config.json if available
      String? version;
      try {
        final configFile = File(path.join(circuitDir, 'config.json'));
        if (await configFile.exists()) {
          final content = await configFile.readAsString();
          final versionMatch = RegExp(r'"version"\s*:\s*"([^"]+)"').firstMatch(content);
          version = versionMatch?.group(1);
        }
      } catch (e) {
        _log.w('Could not read circuit config', error: e);
      }

      return CircuitStatus(isAvailable: true, circuitDir: circuitDir, totalSizeBytes: totalSize, version: version);
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
      _log.i('Starting circuit generation in $circuitDir');

      // Run the FFI call directly (it's async so won't block UI)
      final service = WormholeService();
      final result = await service.generateCircuitBinaries(outputDir: circuitDir, numLeafProofs: numLeafProofs);

      if (result.success) {
        onProgress?.call(1.0, 'Circuit generation complete!');
        _log.i('Circuit generation completed successfully');
        return true;
      } else {
        final error = result.error ?? 'Unknown error';
        onProgress?.call(0.0, 'Generation failed: $error');
        _log.e('Circuit generation failed: $error');
        // Clean up partial generation
        await deleteCircuits();
        return false;
      }
    } catch (e) {
      _log.e('Circuit generation failed', error: e);
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
