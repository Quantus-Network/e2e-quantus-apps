import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Progress callback for circuit extraction operations.
typedef CircuitProgressCallback =
    void Function(double progress, String message);

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
/// Circuit binaries (~163MB) are bundled with the SDK in assets/circuits/
/// and extracted to the app's support directory on first use.
class CircuitManager {
  // Circuit files required for proof generation (bundled in SDK assets/circuits/)
  static const List<String> requiredFiles = [
    'prover.bin',
    'common.bin',
    'verifier.bin',
    'dummy_proof.bin',
    'aggregated_common.bin',
    'aggregated_verifier.bin',
    'aggregated_prover.bin',
    'config.json',
  ];

  // Asset path prefix for SDK package assets
  static const String _assetPrefix = 'packages/quantus_sdk/assets/circuits';

  /// Get the directory where extracted circuit files are stored.
  /// Uses the app's support directory for persistent storage.
  static Future<String> getCircuitDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return path.join(appDir.path, 'circuits');
  }

  /// Check if circuit files are available (extracted from assets).
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
        }
      } catch (e) {
        // Ignore config read errors
      }

      return CircuitStatus(
        isAvailable: true,
        circuitDir: circuitDir,
        totalSizeBytes: totalSize,
        version: version,
        numLeafProofs: numLeafProofs,
      );
    } catch (e) {
      return CircuitStatus.unavailable;
    }
  }

  /// Extract bundled circuit files from SDK assets to the filesystem.
  ///
  /// This is required because the Rust FFI code needs file paths to access
  /// the circuit binaries. Flutter assets cannot be accessed via file paths
  /// directly, so we extract them to the app's support directory.
  ///
  /// This is a fast operation (~10 seconds) since we're just copying files,
  /// not generating circuits.
  Future<bool> extractCircuitsFromAssets({
    CircuitProgressCallback? onProgress,
  }) async {
    try {
      final circuitDir = await getCircuitDirectory();
      final dir = Directory(circuitDir);

      // Create directory if needed
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      onProgress?.call(0.0, 'Extracting circuit files...');

      int extracted = 0;
      for (final fileName in requiredFiles) {
        final progress = extracted / requiredFiles.length;
        onProgress?.call(progress, 'Extracting $fileName...');

        try {
          // Load from bundled SDK assets
          final assetPath = '$_assetPrefix/$fileName';
          final byteData = await rootBundle.load(assetPath);

          // Write to filesystem
          final targetFile = File(path.join(circuitDir, fileName));
          await targetFile.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
            flush: true,
          );
        } catch (e) {
          // Clean up on failure
          await deleteCircuits();
          onProgress?.call(0.0, 'Failed to extract $fileName');
          return false;
        }

        extracted++;
      }

      onProgress?.call(1.0, 'Circuit files ready!');
      return true;
    } catch (e) {
      onProgress?.call(0.0, 'Extraction failed: $e');
      return false;
    }
  }

  /// Delete extracted circuit files (for cleanup or re-extraction).
  Future<void> deleteCircuits() async {
    try {
      final circuitDir = await getCircuitDirectory();
      final dir = Directory(circuitDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore deletion errors
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
