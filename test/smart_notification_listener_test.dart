import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_notification_listener/smart_notification_listener.dart';
import 'package:smart_notification_listener/smart_notification_listener_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartNotification models', () {
    test('fromMap parses actions and canReply', () {
      final n = SmartNotification.fromMap({
        'id': 'k1',
        'packageName': 'com.example',
        'title': 'T',
        'text': 'body',
        'receivedAtFormatted': '2026-01-01 00:00:00',
        'extras': {'a': 'b'},
        'actions': [
          {
            'title': 'Reply',
            'actionId': 'r',
            'inputs': ['key1'],
          },
        ],
      });
      expect(n.id, 'k1');
      expect(n.packageName, 'com.example');
      expect(n.title, 'T');
      expect(n.text, 'body');
      expect(n.receivedAt, '2026-01-01 00:00:00');
      expect(n.extras['a'], 'b');
      expect(n.canReply, isTrue);
      expect(n.actions, hasLength(1));
      expect(n.actions.first.isReplyAction, isTrue);
      expect(n.actions.first.title, 'Reply');
    });

    test('fromMap action without inputs is not reply', () {
      final n = SmartNotification.fromMap({
        'id': 'x',
        'packageName': 'p',
        'title': '',
        'text': '',
        'receivedAtFormatted': '',
        'extras': {},
        'actions': [
          {'title': 'Mark read', 'actionId': 'm', 'inputs': []},
        ],
      });
      expect(n.canReply, isFalse);
      expect(n.actions.first.isReplyAction, isFalse);
    });

    test('empty factory', () {
      final n = SmartNotification.empty();
      expect(n.id, '');
      expect(n.canReply, isFalse);
    });
  });

  group('MethodChannelSmartNotificationListener', () {
    final channel = MethodChannelSmartNotificationListener.methodChannel;

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> mockHandler(
      Future<dynamic> Function(MethodCall call) handler,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
    }

    test('hasPermission forwards channel result', () async {
      await mockHandler((call) async {
        expect(call.method, 'hasPermission');
        return true;
      });
      final impl = MethodChannelSmartNotificationListener();
      expect(await impl.hasPermission(), isTrue);
    });

    test('startNotificationService', () async {
      await mockHandler((call) async {
        expect(call.method, 'startNotificationService');
        return true;
      });
      final impl = MethodChannelSmartNotificationListener();
      expect(await impl.startNotificationService(), isTrue);
    });

    test('stopNotificationService returns false when native returns null', () async {
      await mockHandler((call) async {
        expect(call.method, 'stopNotificationService');
        return null;
      });
      final impl = MethodChannelSmartNotificationListener();
      expect(await impl.stopNotificationService(), isFalse);
    });

    test('disconnect invokes disconnect on channel', () async {
      var invoked = false;
      await mockHandler((call) async {
        if (call.method == 'disconnect') {
          invoked = true;
        }
        return null;
      });
      final impl = MethodChannelSmartNotificationListener();
      await impl.disconnect();
      expect(invoked, isTrue);
    });

    test('forceReconnect coerces to bool', () async {
      await mockHandler((call) async {
        expect(call.method, 'forceReconnect');
        return true;
      });
      final impl = MethodChannelSmartNotificationListener();
      expect(await impl.forceReconnect(), isTrue);
    });

    test('sendReply passes arguments', () async {
      await mockHandler((call) async {
        expect(call.method, 'sendReply');
        expect(call.arguments, {
          'id': 'nid',
          'message': 'hi',
          'actionKey': 'k',
        });
        return true;
      });
      final impl = MethodChannelSmartNotificationListener();
      expect(
        await impl.sendReply(id: 'nid', message: 'hi', actionKey: 'k'),
        isTrue,
      );
    });

    test('isNotificationServiceRunning', () async {
      await mockHandler((call) async {
        expect(call.method, 'isNotificationServiceRunning');
        return false;
      });
      final impl = MethodChannelSmartNotificationListener();
      expect(await impl.isNotificationServiceRunning(), isFalse);
    });

    test('openNotificationSettings', () async {
      await mockHandler((call) async {
        expect(call.method, 'openNotificationSettings');
        return null;
      });
      final impl = MethodChannelSmartNotificationListener();
      await impl.openNotificationSettings();
    });
  });
}
