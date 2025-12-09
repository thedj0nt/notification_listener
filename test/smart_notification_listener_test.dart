import 'package:flutter_test/flutter_test.dart';
import 'package:smart_notification_listener/smart_notification_listener_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmartNotificationListenerPlatform
    with MockPlatformInterfaceMixin
    implements SmartNotificationListenerPlatform {
  
  @override
  Stream<Map<dynamic, dynamic>> get notifications =>
      const Stream.empty(); // return empty stream for test

  @override
  Future<void> openNotificationSettings() async {
    // no-op for test
  }

  @override
  Future<bool> isNotificationServiceRunning() async => true;

  @override
  Future<bool> sendReply({
    required String id,
    required String message,
    String? actionKey,
  }) async {
    // For test, always succeed
    return true;
  }

  @override
  Future<bool> startNotificationService() async {
    return true; // test stub
  }

  @override
  Future<bool> stopNotificationService() async {
    return true; // test stub
  }

  // @override
  // Future<bool> restartNotificationService() async {
  //   return true; // test stub
  // }
  
  @override
  Future<bool> forceReconnect() {
    throw UnimplementedError();
  }
  
  @override
  Future<bool> hasPermission() {
    throw UnimplementedError();
  }
  
  @override
  Future<void> disconnect() {
    throw UnimplementedError();
  }
}