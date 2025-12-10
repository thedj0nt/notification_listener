import 'dart:async'; // Import this for StreamController
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'smart_notification_listener_platform_interface.dart';

class SmartNotificationListener {
  static final SmartNotificationListener _instance = SmartNotificationListener._internal();

  factory SmartNotificationListener() => _instance;

  // Internal StreamController to manage the stream manually
  final StreamController<SmartNotification> _controller = StreamController<SmartNotification>.broadcast();
  StreamSubscription? _nativeSubscription;

  SmartNotificationListener._internal() {
    // Start listening to the native side IMMEDIATELY and PERMANENTLY.
    // This ensures the Sink never detaches even if the UI rebuilds.
    _connectToNative();
  }

  static const EventChannel _eventChannel = EventChannel('smart_notification_listener_event');

  void _connectToNative() {
    if (_nativeSubscription != null) return;

    // We subscribe to the native channel once. 
    // We do NOT store this in a variable accessible to the UI.
    _nativeSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          SmartNotification notification = SmartNotification.empty();
          
          if (event is Map) {
            final map = Map<String, dynamic>.from(event);
            notification = SmartNotification.fromMap(map);
          } else if (event is String) {
            // debugPrint("🔔 Native Status Event: $event");
            notification = SmartNotification.empty()..packageName = event;
          }

          // Forward the data to the controller
          _controller.add(notification);
        } catch (e, stackTrace) {
          debugPrint('Failed to parse SmartNotification: $e\n$stackTrace');
        }
      },
      onError: (error) {
        debugPrint("Native Stream Error: $error");
      },
    );
  }

  /// A broadcast stream of notifications.
  /// Subscribing/Unsubscribing to this will NOT disconnect the native layer.
  Stream<SmartNotification> get notifications {
    return _controller.stream;
  }

  /// Opens the Android system settings screen.
  Future<void> openNotificationSettings() {
    return SmartNotificationListenerPlatform.instance.openNotificationSettings();
  }

  /// Returns `true` if the Android Notification Listener Service is currently active.
  Future<bool> isNotificationServiceRunning() {
    return SmartNotificationListenerPlatform.instance.isNotificationServiceRunning();
  }

  /// Commands the Android service to start.
  Future<bool> startNotificationService() {
    return SmartNotificationListenerPlatform.instance.startNotificationService();
  }

  /// Commands the Android service to stop.
  Future<bool> stopNotificationService() {
    return SmartNotificationListenerPlatform.instance.stopNotificationService();
  }

  /// Disconnects the method channel connection.
  Future<void> disconnect() async {
    // Only here do we actually kill the native connection
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    return SmartNotificationListenerPlatform.instance.disconnect();
  }

  /// Forces the Android service to restart.
  Future<bool> forceReconnect() {
    return SmartNotificationListenerPlatform.instance.forceReconnect();
  }

  /// Checks if the user has granted "Notification Access" permission.
  Future<bool> hasPermission() {
    return SmartNotificationListenerPlatform.instance.hasPermission();
  }

  /// Sends a direct reply to a notification.
  Future<bool> sendReply({
    required SmartNotification notification,
    required String message,
  }) {
    return SmartNotificationListenerPlatform.instance.sendReply(
      id: notification.id,
      message: message,
    );
  }
}

/// Represents a single notification received from Android.
class SmartNotification {
  String id;
  String packageName;
  String title;
  String text;
  String receivedAt;
  Map<String, String> extras;
  List<NotificationAction> actions;

  SmartNotification({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.receivedAt,
    required this.extras,
    required this.actions,
  });

  factory SmartNotification.fromMap(Map<dynamic, dynamic> map) {
    final actionsList = (map['actions'] as List? ?? [])
      .map((actionMap) {
        final Map<String, dynamic> stringMap = {
          for (final entry in (actionMap as Map).entries)
            entry.key.toString(): entry.value,
        };
        return NotificationAction.fromMap(stringMap);
      })
      .toList();

    return SmartNotification(
      id: map['id'] ?? '',
      packageName: map['packageName'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
      receivedAt: map['receivedAtFormatted'] ?? '',
      extras: Map<String, String>.from(map['extras'] ?? {}),
      actions: actionsList,
    );
  }

  factory SmartNotification.empty() => SmartNotification(
    id: '',
    packageName: '',
    title: '',
    text: '',
    actions: [],
    extras: {},
    receivedAt: '',
  );

  bool get canReply => actions.any((a) => a.isReplyAction);
}

class NotificationAction {
  final String title;
  final String actionId;
  final List<String> inputs;

  NotificationAction({
    required this.title,
    required this.actionId,
    required this.inputs,
  });

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      title: map['title'] ?? '',
      actionId: map['actionId'] ?? '',
      inputs: List<String>.from(map['inputs'] ?? []),
    );
  }

  bool get isReplyAction => inputs.isNotEmpty;
}

class RemoteInput {
  final String resultKey;
  final String label;

  RemoteInput({
    required this.resultKey,
    required this.label,
  });

  factory RemoteInput.fromMap(Map<String, dynamic> map) {
    return RemoteInput(
      resultKey: map['resultKey'] ?? '',
      label: map['label'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'resultKey': resultKey,
    'label': label,
  };
}