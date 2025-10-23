import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // Handle links when the app is already open (warm state)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('Received link while app is open: $uri');
      _handleLink(uri, navigatorKey);
    });

    // Handle the link that opened the app (cold state)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      print('Received initial link: $initialUri');
      _handleLink(initialUri, navigatorKey);
    }
  }

  void _handleLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'account') {
      String? accountId;

      // Check for new format: /account?id=123
      if (uri.pathSegments.length == 1 && uri.queryParameters.containsKey('id')) {
        accountId = uri.queryParameters['id'];
      }
      // Check for old format: /account/123
      else if (uri.pathSegments.length == 2) {
        accountId = uri.pathSegments.last;
      }

      if (accountId != null && accountId.isNotEmpty) {
        navigatorKey.currentState?.pushNamed('/account', arguments: accountId);
      } else {
        print('Missing or empty account id');
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
