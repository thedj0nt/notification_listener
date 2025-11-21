import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'smart_notification_listener_method_channel.dart';

abstract class SmartNotificationListenerPlatform extends PlatformInterface {
  SmartNotificationListenerPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmartNotificationListenerPlatform _instance =
      MethodChannelSmartNotificationListener();

  static SmartNotificationListenerPlatform get instance => _instance;

  static set instance(SmartNotificationListenerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Notification stream of type Map
  Stream<Map> get notifications {
    throw UnimplementedError('notifications has not been implemented.');
  }

  /// Open Android notification access settings
  Future<void> openNotificationSettings() {
    throw UnimplementedError('openNotificationSettings() has not been implemented.');
  }

  /// Check if the notification listener service is running
  Future<bool> isNotificationServiceRunning() {
    throw UnimplementedError('isNotificationServiceRunning() has not been implemented.');
  }

  /// Start the Android notification listener service
  Future<bool> startNotificationService() {
    throw UnimplementedError('startNotificationService() has not been implemented.');
  }

  /// Stop the Android notification listener service
  Future<bool> stopNotificationService() {
    throw UnimplementedError('stopNotificationService() has not been implemented.');
  }

  /// Restart the Android notification listener service
  Future<bool> restartNotificationService() {
    throw UnimplementedError('restartNotificationService() has not been implemented.');
  }

  /// Check whether notification listener permission is granted.
  Future<bool> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  /// Send a reply to a notification (simple)
  Future<bool> sendReply({
    required String id,
    required String message,
    String? actionKey,
  }) {
    throw UnimplementedError('sendReply() has not been implemented.');
  }
}
