import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:quantus_sdk/src/utils/timing.dart';

// This set of classes implements redundant endpoints using a strategy to select the best endpoints and to retry failed requests
// on different endpoints.

/// Represents a single endpoint with health tracking.
class Endpoint {
  final String url;
  Duration? latency;
  DateTime? lastSuccess;
  DateTime? lastFailure;
  int consecutiveFailures = 0;

  /// Duration after which a failed endpoint is reconsidered for use.
  static const failureCooldown = Duration(minutes: 5);

  /// Maximum penalty latency for failed endpoints (prevents integer overflow).
  static const maxPenaltyLatency = Duration(hours: 24);

  Endpoint({required this.url, this.latency, this.lastSuccess, this.lastFailure});

  /// Whether this endpoint should be skipped due to recent failures.
  bool get isInCooldown {
    if (lastFailure == null) return false;
    final elapsed = DateTime.now().difference(lastFailure!);
    // Allow retry after cooldown period, scaled by consecutive failures
    final cooldownDuration = failureCooldown * (consecutiveFailures.clamp(1, 10));
    return elapsed < cooldownDuration;
  }

  /// Effective latency for sorting, considering failure state.
  Duration get effectiveLatency {
    if (isInCooldown) {
      // Penalize endpoints in cooldown, but allow them to be tried if all else fails
      return maxPenaltyLatency + Duration(minutes: consecutiveFailures);
    }
    return latency ?? const Duration(seconds: 30);
  }

  void recordSuccess(Duration elapsed) {
    latency = elapsed;
    lastSuccess = DateTime.now();
    consecutiveFailures = 0;
  }

  void recordFailure() {
    lastFailure = DateTime.now();
    consecutiveFailures++;
    // Apply penalty but cap it to prevent overflow
    latency = Duration(seconds: (consecutiveFailures * 60).clamp(60, 86400));
  }
}

class GraphQlEndpointService extends RedundantEndpointService {
  static final GraphQlEndpointService _instance = GraphQlEndpointService._internal();

  factory GraphQlEndpointService() => _instance;

  GraphQlEndpointService._internal()
    : super(endpoints: AppConstants.graphQlEndpoints.map((e) => Endpoint(url: e)).toList());
}

class RpcEndpointService extends RedundantEndpointService {
  static final RpcEndpointService _instance = RpcEndpointService._internal();

  factory RpcEndpointService() => _instance;

  RpcEndpointService._internal() : super(endpoints: AppConstants.rpcEndpoints.map((e) => Endpoint(url: e)).toList());

  /// Returns the URL of the endpoint with the best (lowest) effective latency.
  String get bestEndpointUrl {
    _sortServers();
    return endpoints.first.url;
  }

  Future<T> rpcTask<T>(Future<T> Function(Uri uri) task) async {
    return _executeTask((url) => task(Uri.parse(url)));
  }
}

class RedundantEndpointService {
  final List<Endpoint> endpoints;

  RedundantEndpointService({required this.endpoints});

  Map<String, String> _mergedHeaders(Map<String, String>? headers) {
    return {'Content-Type': 'application/json', ...?headers};
  }

  void _sortServers() {
    endpoints.sort((a, b) => a.effectiveLatency.compareTo(b.effectiveLatency));
  }

  bool _isReachabilityError(dynamic error) {
    return error is SocketException ||
        error is HttpException ||
        (error.toString().contains('Failed host lookup') || error.toString().contains('Connection refused'));
  }

  bool get _connectivityIsOffline {
    return ConnectivityService().currentStatus == NetworkStatus.offline;
  }

  /// Checks if an HTTP response indicates a server error that should trigger failover.
  bool _isServerError(http.Response response) {
    return response.statusCode >= 500 && response.statusCode < 600;
  }

  Future<T> _executeTask<T>(Future<T> Function(String url) task) async {
    dynamic lastError;

    // Sort endpoints by effective latency before attempting
    _sortServers();

    for (final endpoint in endpoints) {
      final startTime = DateTime.now();

      try {
        final result = await task(endpoint.url);

        // Check for server errors in HTTP responses
        if (result is http.Response && _isServerError(result)) {
          lastError = Exception('Server error: ${result.statusCode}');
          logEndpointFailure(endpoint, lastError);
          continue; // Try next endpoint
        }

        final elapsed = DateTime.now().difference(startTime);
        printTiming('endpoint task ${endpoint.url}', elapsed.inMilliseconds);
        endpoint.recordSuccess(elapsed);

        _sortServers();
        return result;
      } catch (e) {
        lastError = e;
        printTiming('endpoint task FAILED ${endpoint.url}', DateTime.now().difference(startTime).inMilliseconds);
        logEndpointFailure(endpoint, e);
      }
    }

    _sortServers();
    throw lastError ?? Exception('All endpoints failed');
  }

  void logEndpointFailure(Endpoint endpoint, dynamic error) {
    if (!_connectivityIsOffline) {
      print('endpoint failure: ${endpoint.url}: $error');
      if (_isReachabilityError(error)) {
        print('Reachability error on endpoint: ${endpoint.url}: $error');
      }
      endpoint.recordFailure();
    }
  }

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    return _executeTask((url) => http.get(Uri.parse('$url$path'), headers: _mergedHeaders(headers)));
  }

  Future<http.Response> post({String? path, Map<String, String>? headers, String? body}) async {
    return _executeTask(
      (url) => http.post(Uri.parse('$url${(path ?? '')}'), body: body, headers: _mergedHeaders(headers)),
    );
  }
}
