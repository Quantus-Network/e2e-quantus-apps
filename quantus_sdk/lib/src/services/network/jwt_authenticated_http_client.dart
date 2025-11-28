import 'package:http/http.dart' as http;

class JWTAuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Future<String> Function() _getAccessToken;

  JWTAuthenticatedHttpClient(this._getAccessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _getAccessToken();

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = 'application/json';

    return _inner.send(request);
  }
}
