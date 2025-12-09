import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'smart_notification_listener_platform_interface.dart';

/// A Flutter wrapper for listening and replying to Android notifications.
/// 
/// This class provides a singleton instance to manage the connection to the
/// Android Notification Service.
class SmartNotificationListener {
  static final SmartNotificationListener _instance = SmartNotificationListener._internal();

  factory SmartNotificationListener() => _instance;

  SmartNotificationListener._internal();

  /// A broadcast stream of notifications received from the Android service.
  static const EventChannel _eventChannel = EventChannel('smart_notification_listener_event');

  /// A broadcast stream of incoming notifications.
  /// 
  /// This stream transforms the raw map data from Android into 
  /// typed [SmartNotification] objects.
  /// 
  /// It also handles special status messages (like 'connected') by returning
  /// an empty notification with the packageName set to the status.
  Stream<SmartNotification> get notifications {
    return _eventChannel.receiveBroadcastStream().map((event) {
      try {
        // 1. Check if event is a MAP (Actual Notification)
        if (event is Map) {
          final map = Map<String, dynamic>.from(event);
          return SmartNotification.fromMap(map);
        } 
        
        // 2. Check if event is a STRING (Status message like "connected")
        if (event is String) {
          debugPrint("🔔 Native Status Event: $event");
          // Return a special empty notification to signal status change
          return SmartNotification.empty()..packageName = event;
        }

        return SmartNotification.empty();
      } catch (e, stackTrace) {
        debugPrint('Failed to parse SmartNotification: $e\n$stackTrace');
        return SmartNotification.empty();
      }
    });
  }

  /// Opens the Android system settings screen where the user can grant 
  /// "Notification Access" permission to this app.
  Future<void> openNotificationSettings() {
    return SmartNotificationListenerPlatform.instance.openNotificationSettings();
  }

  /// Returns `true` if the Android Notification Listener Service is currently active.
  Future<bool> isNotificationServiceRunning() {
    return SmartNotificationListenerPlatform.instance.isNotificationServiceRunning();
  }

  // Commands the Android service to start.
  Future<bool> startNotificationService() {
    return SmartNotificationListenerPlatform.instance.startNotificationService();
  }

  /// Commands the Android service to stop.
  Future<bool> stopNotificationService() {
    return SmartNotificationListenerPlatform.instance.stopNotificationService();
  }

  /// Disconnects the method channel connection.
  Future<void> disconnect() async {
    return SmartNotificationListenerPlatform.instance.disconnect();
  }

  /// Forces the Android service to restart.
  /// 
  /// Useful if the OS has silently killed the service. This method toggles
  /// the component state to trigger a system-level restart.
  Future<bool> forceReconnect() {
    return SmartNotificationListenerPlatform.instance.forceReconnect();
  }

  /// Checks if the user has granted "Notification Access" permission.
  Future<bool> hasPermission() {
    return SmartNotificationListenerPlatform.instance.hasPermission();
  }

  /// Sends a direct reply to a notification.
  /// 
  /// This mimics the user typing into the notification bar inline reply.
  /// 
  /// [notification]: The notification object received from the stream.
  /// [message]: The text you want to send.
  /// 
  /// Returns `true` if the reply intent was successfully fired.
  Future<bool> sendReply({
    required SmartNotification notification,
    required String message,
  }) {
    return SmartNotificationListenerPlatform.instance.sendReply(
      id: notification.id, // maps to sbn.key
      message: message,
    );
  }
}

/// Represents a single notification received from Android.
class SmartNotification {
  /// The unique key assigned by Android. Required for replying.
  String id;

  /// The package name of the app that posted the notification (e.g., 'com.whatsapp').
  String packageName;

  /// The title of the notification (usually the sender's name).
  String title;

  /// The main text body of the notification
  String text;

  /// Formatted string of the time received.
  String receivedAt;

  /// Raw extra data from the notification bundle.
  Map<String, String> extras;

  /// List of actionable buttons available on this notification.
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

  /// Returns `true` if this notification contains an action that accepts text input.
  bool get canReply => actions.any((a) => a.isReplyAction);
}

/// Represents an action button attached to a notification.
class NotificationAction {
  final String title;
  final String actionId;

  /// List of input keys. If not empty, this action accepts text input.
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

  /// Helper to check if this action is a "Reply" button.
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
