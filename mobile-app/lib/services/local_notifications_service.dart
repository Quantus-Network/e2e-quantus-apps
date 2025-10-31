import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class LocalNotificationsService {
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  final _notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Stream controller to broadcast deserialized event objects
  final StreamController<TransactionEvent?> _onNotificationClick = StreamController<TransactionEvent?>.broadcast();
  // Public stream for the UI to listen to
  Stream<TransactionEvent?> get onNotificationClick => _onNotificationClick.stream;

  // Helper function to serialize the payload
  String? _serializePayload(TransactionEvent event) {
    String eventType;
    Map<String, dynamic> eventData;

    if (event is TransferEvent) {
      eventType = 'transfer';
      eventData = event.toJson();
    } else if (event is ReversibleTransferEvent) {
      eventType = 'reversible_transfer';
      eventData = event.toJson();
    } else {
      // Unknown type, don't serialize
      return null;
    }

    // Wrap the event data with a type identifier
    final payloadMap = {'eventType': eventType, 'data': eventData};
    return jsonEncode(payloadMap);
  }

  TransactionEvent? _deserializePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      final eventType = payloadMap['eventType'] as String;
      final data = payloadMap['data'] as Map<String, dynamic>;

      switch (eventType) {
        case 'transfer':
          return TransferEvent.fromJson(data);
        case 'reversible_transfer':
          return ReversibleTransferEvent.fromJson(data);
        default:
          return null;
      }
    } catch (e) {
      print('Error deserializing notification payload: $e');
      return null;
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _onNotificationClick.add(_deserializePayload(response.payload));
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'local_channel_id',
        'Local Notification',
        channelDescription: 'Wallet local notification channel',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> initService() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Handle terminated state
    final notificationAppLaunchDetails = await _notificationPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      _onNotificationClick.add(_deserializePayload(payload));
    }

    _isInitialized = true;
  }

  Future<void> showNotification({required int id, required String title, String? body, TransactionEvent? event}) async {
    final String? payload = event != null ? _serializePayload(event) : null;

    return _notificationPlugin.show(id, title, body, _notificationDetails(), payload: payload);
  }

  void dispose() {
    _onNotificationClick.close();
  }
}
