import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

void main() {
  group('RedundantEndpointService path safety', () {
    test('_buildSafeUri rejects userinfo-style paths that would change host', () {
      expect(
        () => RedundantEndpointService.buildSafeUriForTest('https://api.example.com', '@attacker.example/collect'),
        throwsArgumentError,
      );
    });

    test('_buildSafeUri rejects protocol-relative paths', () {
      expect(
        () => RedundantEndpointService.buildSafeUriForTest('https://api.example.com', '//attacker.example/path'),
        throwsArgumentError,
      );
    });

    test('_buildSafeUri rejects absolute URLs', () {
      expect(
        () => RedundantEndpointService.buildSafeUriForTest('https://api.example.com', 'https://attacker.example/path'),
        throwsArgumentError,
      );
    });

    test('_buildSafeUri allows normal relative paths', () {
      final uri = RedundantEndpointService.buildSafeUriForTest('https://api.example.com', '/v1/data');
      expect(uri.host, 'api.example.com');
      expect(uri.path, '/v1/data');
    });

    test('_buildSafeUri allows paths without leading slash', () {
      final uri = RedundantEndpointService.buildSafeUriForTest('https://api.example.com', 'v1/data');
      expect(uri.host, 'api.example.com');
      expect(uri.path, contains('v1/data'));
    });

    test('_buildSafeUri allows query strings', () {
      final uri = RedundantEndpointService.buildSafeUriForTest('https://api.example.com', '?query=value');
      expect(uri.host, 'api.example.com');
      expect(uri.query, 'query=value');
    });

    test('_buildSafeUri preserves base URL scheme', () {
      final uri = RedundantEndpointService.buildSafeUriForTest('https://api.example.com', '/path');
      expect(uri.scheme, 'https');
    });

    test('_buildSafeUri works with empty path', () {
      final uri = RedundantEndpointService.buildSafeUriForTest('https://api.example.com', '');
      expect(uri.host, 'api.example.com');
    });

    test('_buildSafeUri preserves port if present', () {
      final uri = RedundantEndpointService.buildSafeUriForTest('https://api.example.com:8080', '/path');
      expect(uri.host, 'api.example.com');
      expect(uri.port, 8080);
    });
  });
}
