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
    // Check if the path matches your expected format of /account/:id
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'account') {
      final accountId = uri.pathSegments.last;
      
      // Use the navigator key to push the new route.
      // We use `currentState` because the key is attached to the Navigator's state.
      navigatorKey.currentState?.pushNamed(
        '/account',
        arguments: accountId, 
      );
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}