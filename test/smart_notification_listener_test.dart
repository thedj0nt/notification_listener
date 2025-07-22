import 'package:flutter_test/flutter_test.dart';
import 'package:smart_notification_listener/smart_notification_listener_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmartNotificationListenerPlatform
    with MockPlatformInterfaceMixin
    implements SmartNotificationListenerPlatform {
  
  // @override
  // Future<String?> getPlatformVersion() => Future.value('42');

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
  Future<bool> sendReply({required String id, required String message}) async => true;
  
  @override
  Future<bool> startNotificationService() {
    // TODO: implement startNotificationService
    throw UnimplementedError();
  }
  
  @override
  Future<bool> stopNotificationService() {
    // TODO: implement stopNotificationService
    throw UnimplementedError();
  }
  
  @override
  Future<bool> restartNotificationService() {
    // TODO: implement restartNotificationService
    throw UnimplementedError();
  }
}
