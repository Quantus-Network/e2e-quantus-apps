import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/models/notification_models.dart';
import 'package:resonance_network_wallet/services/local_notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maximum number of notifications to keep (FIFO)
const int maxNotifications = 64;

/// Key for storing notifications in shared preferences
const String notificationsStorageKey = 'notifications';
const String notificationConfigKey = 'notification_config';

/// Notification provider that manages the notification state
final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationData>>((ref) {
  final localNotificationsService = ref.watch(localNotificationsServiceProvider);

  return NotificationNotifier(localNotificationsService);
});

/// Notifier that manages notification state with persistence and streams
class NotificationNotifier extends StateNotifier<List<NotificationData>> {
  final LocalNotificationsService _localNotificationsService;

  NotificationNotifier(this._localNotificationsService) : super([]) {
    _initialize();
  }

  // Stream controllers for different notification sources
  final StreamController<NotificationData> _localAlertController = StreamController.broadcast();
  final StreamController<NotificationData> _localPushController = StreamController.broadcast();
  final StreamController<NotificationData> _remotePushController = StreamController.broadcast();

  NotificationConfig _config = const NotificationConfig(
    enabled: true,
    sound: true,
    vibration: true,
    showBadge: true,
    sentTokensEnabled: true,
    receivedTokensEnabled: true,
    recoveryTimerEndingEnabled: true,
    reversibleTransactionsEnabled: true,
  );
  NotificationConfig get config => _config;

  // Timer for periodic cleanup of expired notifications
  Timer? _cleanupTimer;

  /// Combined stream of all notifications
  Stream<NotificationData> get notificationStream =>
      StreamGroup.merge([_localAlertController.stream, _localPushController.stream, _remotePushController.stream]);

  /// Initialize the notifier by loading persisted notifications
  Future<void> _initialize() async {
    await _loadConfig();
    await _loadPersistedNotifications();
    _startCleanupTimer();
    _cleanupExpiredNotifications();
  }

  /// Start periodic cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredNotifications();
    });
  }

  /// Get OS-level notification status
  Future<OSNotificationSettings> getOSSettings() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.status;
      final isGranted = status.isGranted;

      // If permission is granted, all features are available
      return OSNotificationSettings(enabled: isGranted, sound: isGranted, vibration: isGranted, badge: isGranted);
    }

    return const OSNotificationSettings(enabled: false, sound: false, vibration: false, badge: false);
  }

  /// Check if notifications can be shown (OS + app level + notification type)
  Future<bool> canShowNotification(NotificationIntent type) async {
    // Check app-level master setting
    if (!_config.enabled) {
      print('Notifications disabled at app level');
      return false;
    }

    // Check specific notification type setting
    if (!_config.isIntentEnabled(type)) {
      print('Notification type ${type.name} is disabled');
      return false;
    }

    // Check OS-level permission
    final osSettings = await getOSSettings();
    if (!osSettings.enabled) {
      print('Notifications disabled at OS level');
      return false;
    }

    return true;
  }

  /// Check if any notifications can be shown (master check)
  Future<bool> canShowNotifications() async {
    if (!_config.enabled) {
      print('Notifications disabled at app level');
      return false;
    }

    final osSettings = await getOSSettings();
    if (!osSettings.enabled) {
      print('Notifications disabled at OS level');
      return false;
    }

    return true;
  }

  /// Load notifications from shared preferences
  Future<void> _loadPersistedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(notificationsStorageKey) ?? [];

      final notifications = notificationsJson
          .map((json) => NotificationData.fromJson(jsonDecode(json)))
          .where((notification) => notification.persistent)
          .toList();

      state = notifications;
    } catch (e) {
      // If loading fails, start with empty state
      state = [];
    }
  }

  /// Save notifications to shared preferences
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = state
        .where((notification) => notification.persistent)
        .map((notification) => jsonEncode(notification.toJson()))
        .toList();

    await prefs.setStringList(notificationsStorageKey, notificationsJson);
  }

  /// Add a new notification
  Future<void> addNotification(NotificationData notification) async {
    // Check if this specific notification intent can be shown
    if (!await canShowNotification(notification.intent)) {
      print('Cannot show ${notification.intent.name} notification: disabled or permission not granted');
      return;
    }

    // Enforce 64 notification limit (FIFO)
    if (state.length >= maxNotifications) {
      // Remove oldest notification
      state = state.sublist(1);
    }

    // Add new notification
    state = [...state, notification];

    // Save to persistence if persistent
    if (notification.persistent) {
      _saveNotifications();
    }

    // Send to appropriate stream
    _sendToStream(notification);

    switch (notification.source) {
      case NotificationSource.local:
        // No need to handle, because it already shown by default when we added to the state array.
        break;
      case NotificationSource.push:
        _localNotificationsService.showOrScheduleNotification(notification);
        break;
      case NotificationSource.remote:
        // 
        break;
    }
  }

  /// Remove a notification by ID
  void removeNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
    _saveNotifications();
  }

  /// Clear all notifications
  void clearAll() {
    state = [];
    _saveNotifications();
  }

  /// Get notifications for a specific account
  List<NotificationData> getNotificationsForAccount(String accountId) {
    return state.where((notification) => notification.metadata?['accountId'] == accountId).toList();
  }

  /// Get notifications by type
  List<NotificationData> getNotificationsByType(NotificationType type) {
    return state.where((notification) => notification.type == type).toList();
  }

  /// Send notification to appropriate stream
  void _sendToStream(NotificationData notification) {
    switch (notification.source) {
      case NotificationSource.local:
        _localAlertController.add(notification);
        break;
      case NotificationSource.push:
        _localPushController.add(notification);
        break;
      case NotificationSource.remote:
        _remotePushController.add(notification);
        break;
    }
  }

  /// Clean up expired notifications
  void _cleanupExpiredNotifications() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final notification in state) {
      if (notification.expiryTime != null && notification.expiryTime!.isBefore(now)) {
        expiredIds.add(notification.id);
      }
    }

    if (expiredIds.isNotEmpty) {
      state = state.where((notification) => !expiredIds.contains(notification.id)).toList();
      _saveNotifications();
    }
  }

  /// Load saved configuration from storage
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(notificationConfigKey);

      if (configJson != null) {
        _config = NotificationConfig.fromJson(Map<String, dynamic>.from(jsonDecode(configJson)));
      }
    } catch (e) {
      print('Error loading notification config: $e');
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(notificationConfigKey, jsonEncode(_config.toJson()));
    } catch (e) {
      print('Error saving notification config: $e');
    }
  }

  /// Update app-level notification configuration
  Future<void> updateConfig(NotificationConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
  }

  /// Add convenience methods for specific notification types
  void addTransactionFailed({
    required String accountName,
    required String errorMessage,
    required PendingTransactionEvent transactionData,
  }) {
    final notification = NotificationTemplates.transactionFailed(
      accountName: accountName,
      transactionData: transactionData,
      errorMessage: errorMessage,
    );
    addNotification(notification);
  }

  void addBalanceLow({required String accountName, required String accountId}) {
    final notification = NotificationTemplates.balanceLow(accountName: accountName, accountId: accountId);
    addNotification(notification);
  }

  void addAccountAdded({required String accountName, required String accountId}) {
    final notification = NotificationTemplates.accountAdded(accountName: accountName, accountId: accountId);
    addNotification(notification);
  }

  void addReversibleTransactionReminder({
    required String accountName,
    required ReversibleTransferEvent transactionData,
  }) {
    final notification = NotificationTemplates.reversibleTransactionReminder(
      accountName: accountName,
      transactionData: transactionData,
    );
    addNotification(notification);
  }

  void addTokenSent({required String accountName, required TransferEvent transactionData}) {
    final notification = NotificationTemplates.tokenSent(accountName: accountName, transactionData: transactionData);
    addNotification(notification);
  }

  /// Stub for remote notifications (to be implemented later)
  void addRemoteNotification(NotificationData notification) {
    // This is a placeholder for future Firebase/APNs integration
    addNotification(notification.copyWith(source: NotificationSource.remote));
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _localAlertController.close();
    _localPushController.close();
    _remotePushController.close();
    super.dispose();
  }
}
