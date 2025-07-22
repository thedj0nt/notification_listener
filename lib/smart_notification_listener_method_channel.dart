import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'smart_notification_listener_platform_interface.dart';

class MethodChannelSmartNotificationListener
    extends SmartNotificationListenerPlatform {
  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel('smart_notification_listener');

  static const EventChannel _eventChannel =
      EventChannel('smart_notification_listener_event');

  Stream<Map<String, dynamic>>? _notificationStream;

  @override
  Stream<Map<String, dynamic>> get notifications {
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
    final result =
        await methodChannel.invokeMethod<bool>('isNotificationServiceRunning');
    return result ?? false;
  }

  @override
  Future<bool> startNotificationService() async {
    final result =
        await methodChannel.invokeMethod<bool>('startNotificationService');
    return result ?? false;
  }

  @override
  Future<bool> stopNotificationService() async {
    final result =
        await methodChannel.invokeMethod<bool>('stopNotificationService');
    return result ?? false;
  }

  @override
  Future<bool> restartNotificationService() async {
    final result =
        await methodChannel.invokeMethod<bool>('restartNotificationService');
    return result ?? false;
  }

  @override
  Future<bool> sendReply({
    required String id,
    required String message,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('sendReply', {
      'id': id,
      'message': message,
    });
    return result ?? false;
  }
}
