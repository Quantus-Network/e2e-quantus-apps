import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

/// Service for handling hardware wallet interactions, specifically Keystone.
/// This includes UR (Uniform Resources) encoding/decoding and signature verification.
class HardwareWalletService {
  
  /// Encodes a payload (bytes) into a single UR string.
  /// Throws if encoding fails.
  String encodePayloadAsUr(List<int> payload) {
    final urParts = encodeUr(data: payload);
    if (urParts.isEmpty) {
      throw Exception('Failed to encode UR: empty result');
    }
    // Keystone usually expects a single part for simple transactions, 
    // or handles multipart if the payload is large. 
    // encodeUr returns a list of parts.
    return urParts.first;
  }

  /// Checks if a collection of UR parts forms a complete payload.
  bool isComplete(List<String> urParts) {
    if (urParts.isEmpty) return false;
    return isCompleteUr(urParts: urParts);
  }

  /// Parses the total fragment count from a UR part string (e.g., "UR:Type/1-5/...").
  int? getTotalFragmentCount(List<String> urParts) {
    if (urParts.isEmpty) return null;
    
    for (final part in urParts) {
      // Regex to find the sequence indicator like "1-5" in the UR string
      final match = RegExp(r'/(\d+)-(\d+)/').firstMatch(part);
      if (match != null) {
        final total = int.tryParse(match.group(2) ?? '');
        if (total != null && total > 0) return total;
      }
    }
    return null;
  }

  /// Decodes a list of UR parts into the raw bytes of the signature/payload.
  Uint8List decodeSignatureUr(List<String> signatureQRParts) {
    if (signatureQRParts.isEmpty) {
      throw Exception('No signature parts provided');
    }
    
    // Check if it's a UR format
    if (!signatureQRParts.first.toUpperCase().startsWith('UR:')) {
       throw Exception('Invalid signature format: Not a UR code');
    }

    try {
      return decodeUr(urParts: signatureQRParts);
    } catch (e) {
      throw Exception('Invalid UR format: $e');
    }
  }

  /// Validates the decoded signature bytes and splits them into signature and public key.
  /// Returns a record (signature, publicKey).
  ({Uint8List signature, Uint8List publicKey}) parseSignatureBytes(Uint8List signatureBytes) {
    final expectedTotalSize = signatureSize + publicKeySize;

    if (signatureBytes.length != expectedTotalSize) {
      throw Exception(
        'Invalid signature length: expected $expectedTotalSize bytes, got ${signatureBytes.length}'
      );
    }

    final signature = signatureBytes.sublist(0, signatureSize);
    final publicKey = signatureBytes.sublist(signatureSize);

    return (signature: signature, publicKey: publicKey);
  }

  /// Helper for debugging: simulates a hardware signature using a local keypair.
  Future<Uint8List> simulateSignature(Account account, UnsignedTransactionData unsignedData) async {
    final debugWallet = await account.getKeypair();
    final signature = signMessage(keypair: debugWallet, message: unsignedData.encodedPayloadToSign);
    
    final signatureWithPublicKey = Uint8List(signature.length + debugWallet.publicKey.length);
    signatureWithPublicKey.setAll(0, signature);
    signatureWithPublicKey.setAll(signature.length, debugWallet.publicKey);
    
    return signatureWithPublicKey;
  }
}

final hardwareWalletServiceProvider = Provider<HardwareWalletService>((ref) {
  return HardwareWalletService();
});

