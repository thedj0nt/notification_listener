import 'package:flutter/foundation.dart';

import 'smart_notification_listener_platform_interface.dart';

/// A Flutter wrapper for listening and replying to Android notifications.
class SmartNotificationListener {
  static final SmartNotificationListener _instance = SmartNotificationListener._internal();

  factory SmartNotificationListener() => _instance;

  SmartNotificationListener._internal();

  /// A broadcast stream of notifications received from the Android service.
  Stream<SmartNotification> get notifications {
    return SmartNotificationListenerPlatform.instance.notifications.map((event) {
      try {
          final map = event.map((key, value) => MapEntry(key.toString(), value));
          return SmartNotification.fromMap(map);
      } catch (e, stackTrace) {
        debugPrint('Failed to parse SmartNotification: $e\n$stackTrace');
        return SmartNotification.empty();
      }
    });
  }

  /// Opens the Android settings screen to grant notification access.
  Future<void> openNotificationSettings() {
    return SmartNotificationListenerPlatform.instance.openNotificationSettings();
  }

  /// Returns `true` if the notification listener service is currently running.
  Future<bool> isNotificationServiceRunning() {
    return SmartNotificationListenerPlatform.instance.isNotificationServiceRunning();
  }

  /// Starts the notification listener service.
  Future<bool> startNotificationService() {
    return SmartNotificationListenerPlatform.instance.startNotificationService();
  }

  /// Stops the notification listener service.
  Future<bool> stopNotificationService() {
    return SmartNotificationListenerPlatform.instance.stopNotificationService();
  }

  /// Restarts the notification listener service.
  Future<bool> restartNotificationService() {
    return SmartNotificationListenerPlatform.instance.restartNotificationService();
  }

  Future<bool> hasPermission() {
    return SmartNotificationListenerPlatform.instance.hasPermission();
  }

  /// Sends a reply using the given notification action.
  /// Automatically uses the correct ID and input key.
  /// Returns `true` if the reply was successfully sent.
  Future<bool> sendReply({
    required SmartNotification notification,
    required String message,
    NotificationAction? action,
  }) {
    return SmartNotificationListenerPlatform.instance.sendReply(
      id: notification.id, // maps to sbn.key
      message: message,
      actionKey: action?.inputs.isNotEmpty == true
        ? action!.inputs.first // remoteInput key
        : action?.title,     // fallback to title
    );
  }
}

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

  /// Add this getter
  bool get canReply => actions.any((a) => a.isReplyAction);
}

/// Represents an actionable button or input field in a notification.
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

  /// Helper getter
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
