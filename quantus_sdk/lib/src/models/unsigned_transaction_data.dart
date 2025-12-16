import 'dart:typed_data';

import 'package:polkadart/polkadart.dart';

class UnsignedTransactionData {
  final SigningPayload payloadToSign;
  final Uint8List signer;
  final dynamic registry;

  Uint8List get encodedPayload => payloadToSign.encode(registry);

  UnsignedTransactionData({
    required this.payloadToSign,
    required this.signer,
    required this.registry,
  });
}
