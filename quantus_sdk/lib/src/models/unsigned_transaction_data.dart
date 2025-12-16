import 'dart:typed_data';

class UnsignedTransactionData {
  Uint8List payloadToSign;
  Uint8List signer;
  Uint8List method;
  int eraPeriod;
  int blockNumber;
  String blockHash;
  int nonce;
  int tip;
  dynamic registry;

  UnsignedTransactionData({
    required this.payloadToSign,
    required this.signer,
    required this.method,
    required this.eraPeriod,
    required this.blockNumber,
    required this.blockHash,
    required this.nonce,
    required this.tip,
    required this.registry,
  });
}
