import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'smart_notification_listener_platform_interface.dart';

/// An implementation of [SmartNotificationListenerPlatform] that uses method channels.
class MethodChannelSmartNotificationListener extends SmartNotificationListenerPlatform {
  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel('smart_notification_listener');

  static const EventChannel _eventChannel = EventChannel('smart_notification_listener_event');

  Stream<Map<String, dynamic>>? _notificationStream;

  @override
  Stream<Map<String, dynamic>> get notifications {
    // Ensures we don't create multiple streams.
    _notificationStream ??= _eventChannel
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event));
    return _notificationStream!;
  }

  @override
  Future<void> openNotificationSettings() async {
    await methodChannel.invokeMethod('openNotificationSettings');
  }

  @override
  Future<bool> isNotificationServiceRunning() async {
    final result = await methodChannel.invokeMethod<bool>('isNotificationServiceRunning');
    return result ?? false;
  }

  @override
  Future<bool> startNotificationService() async {
    final result = await methodChannel.invokeMethod<bool>('startNotificationService');
    return result ?? false;
  }

  @override
  Future<bool> stopNotificationService() async {
    final result = await methodChannel.invokeMethod<bool>('stopNotificationService');
    return result ?? false;
  }

  // Add this method to your class
  @override
  Future<void> disconnect() async {
    try {
      await methodChannel.invokeMethod('disconnect');
    } catch (e) {
      // print("Error disconnecting: $e");
    }
  }

  @override
  Future<bool> forceReconnect() async {
    final result = await methodChannel.invokeMethod("forceReconnect");
    return result == true;
  }

  @override
  Future<bool> hasPermission() async {
    final result = await methodChannel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  @override
  Future<bool> sendReply({
    required String id,
    required String message,
    String? actionKey,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('sendReply', {
      'id': id,
      'message': message,
      if (actionKey != null) 'actionKey': actionKey,
    });
    return result ?? false;
  }
}
