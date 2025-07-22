import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:smart_notification_listener/smart_notification_listener_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // MethodChannelSmartNotificationListener platform = MethodChannelSmartNotificationListener();
  const MethodChannel channel = MethodChannel('smart_notification_listener');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await platform.getPlatformVersion(), '42');
  // });
}
