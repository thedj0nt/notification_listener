import 'smart_notification_listener_platform_interface.dart';

/// A Flutter wrapper for listening and replying to Android notifications.
class SmartNotificationListener {
  static final SmartNotificationListener _instance = SmartNotificationListener._internal();

  factory SmartNotificationListener() => _instance;

  SmartNotificationListener._internal();

  /// A broadcast stream of notifications received from the Android service.
  Stream<SmartNotification> get notifications {
    return SmartNotificationListenerPlatform.instance.notifications.map(
       (event) => SmartNotification.fromMap(Map<dynamic, dynamic>.from(event)),
    );
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

  /// Sends a direct reply to a notification using its ID.
  ///
  /// Returns `true` if the reply was successfully sent.
  Future<bool> sendReply({
    required String id,
    required String message,
  }) {
    return SmartNotificationListenerPlatform.instance.sendReply(
      id: id,
      message: message,
    );
  }
}

class SmartNotification {
  String id;
  String package;
  String title;
  String text;
  bool hasReply;
  String receivedAt;
  Map<String, String> extras;

  SmartNotification({
    required this.id,
    required this.package,
    required this.title,
    required this.text,
    required this.hasReply,
    required this.receivedAt,
    required this.extras,
  });

  factory SmartNotification.fromMap(Map<dynamic, dynamic> map) {
    return SmartNotification(
      id: map['id'] ?? '',
      package: map['package'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
      hasReply: map['hasReply'] ?? false,
      receivedAt: map['receivedAtFormatted'] ?? '',
      extras: Map<String, String>.from(map['extras'] ?? {}),
    );
  }
}
