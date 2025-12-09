import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'smart_notification_listener_method_channel.dart';

/// The interface that implementations of smart_notification_listener must implement.
/// 
/// Platform implementations should extend this class rather than implementing it as an interface.
abstract class SmartNotificationListenerPlatform extends PlatformInterface {
  SmartNotificationListenerPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmartNotificationListenerPlatform _instance =
      MethodChannelSmartNotificationListener();

  /// The default instance of [SmartNotificationListenerPlatform] to use.
  static SmartNotificationListenerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own platform-specific class.
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

  // Add this method to your class
  Future<void> disconnect() async {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Restart the Android notification listener service
  Future<bool> forceReconnect() {
    throw UnimplementedError('forceReconnect() has not been implemented.');
  }

  /// Check whether notification listener permission is granted.
  Future<bool> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  /// Send a reply to a notification
  Future<bool> sendReply({
    required String id,
    required String message,
    String? actionKey,
  }) {
    throw UnimplementedError('sendReply() has not been implemented.');
  }
}
