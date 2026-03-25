import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/firebase_options.dart';
import 'package:resonance_network_wallet/providers/feature_flags_provider.dart';
import 'package:resonance_network_wallet/services/firebase_messaging_service.dart';
import 'package:resonance_network_wallet/services/history_polling_manager.dart';
import 'package:resonance_network_wallet/services/local_notifications_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Widget that initializes the polling services for the entire app.
/// This should be placed high in the widget tree, typically in your main app
/// widget.
class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isEnablingRemoteNotifications = false;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // `ref.listen` must be registered during `build`; using `listenManual` allows
      // setting up the side-effect listener from `initState`/async code.
      ref.listenManual<FeatureFlagsModel>(featureFlagsProvider, (previous, next) {
        if (!next.enableRemoteNotifications) return;
        unawaited(_enableRemoteNotificationsIfNeeded());
      });

      final notificationService = ref.read(localNotificationsServiceProvider);
      await notificationService.init();

      // If cached flags already allow remote notifications, enable immediately.
      if (ref.read(featureFlagsProvider).enableRemoteNotifications) {
        unawaited(_enableRemoteNotificationsIfNeeded());
      }

      ref.read(historyPollingManagerProvider);
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e\n$stackTrace');
    }
  }

  Future<void> _enableRemoteNotificationsIfNeeded() async {
    if (_isEnablingRemoteNotifications) return;
    _isEnablingRemoteNotifications = true;

    // If Firebase wasn't initialized at startup (because cached flags were false),
    // do it now.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.getOptionsForEnvironment());
    }

    final fcmService = ref.read(firebaseMessagingServiceProvider);
    await fcmService.init(); // This requests notification permission.

    // Ensure navigatorKey.currentState is attached before handling any initial message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fcmService.setupNotificationTapHandlers(navigatorKey);
    });

    _isEnablingRemoteNotifications = false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
