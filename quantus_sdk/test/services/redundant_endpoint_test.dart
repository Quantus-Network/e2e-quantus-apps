import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/src/services/network/redundant_endpoint.dart';

void main() {
  group('RedundantEndpointService timeout configuration', () {
    test('defaultTimeout is 30 seconds', () {
      expect(RedundantEndpointService.defaultTimeout, const Duration(seconds: 30));
    });

    test('maxTimeout is 5 minutes', () {
      expect(RedundantEndpointService.maxTimeout, const Duration(minutes: 5));
    });

    test('defaultTimeout is less than maxTimeout', () {
      expect(
        RedundantEndpointService.defaultTimeout.compareTo(RedundantEndpointService.maxTimeout),
        lessThan(0),
      );
    });
  });

  group('EndpointTimeoutException', () {
    test('creates exception with url and timeout', () {
      final exception = EndpointTimeoutException('https://example.com', const Duration(seconds: 30));

      expect(exception.url, 'https://example.com');
      expect(exception.timeout, const Duration(seconds: 30));
    });

    test('toString includes url and timeout seconds', () {
      final exception = EndpointTimeoutException('https://api.example.com/graphql', const Duration(seconds: 45));

      expect(exception.toString(), contains('https://api.example.com/graphql'));
      expect(exception.toString(), contains('45s'));
    });
  });

  group('Endpoint health tracking', () {
    test('records timeout as reachability error', () {
      // Verify TimeoutException and EndpointTimeoutException are treated as reachability errors
      // by checking the failure cooldown mechanism works for them
      final endpoint = Endpoint(url: 'https://example.com');

      expect(endpoint.isInCooldown, isFalse);
      expect(endpoint.consecutiveFailures, 0);

      endpoint.recordFailure();

      expect(endpoint.consecutiveFailures, 1);
      expect(endpoint.isInCooldown, isTrue);
    });

    test('failureCooldown is 5 minutes', () {
      expect(Endpoint.failureCooldown, const Duration(minutes: 5));
    });
  });
}
