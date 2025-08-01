# smart_notification_listener

A Flutter plugin for Android that allows your app to **listen to system notifications** and **send replies directly** to supported notifications like WhatsApp, Telegram, etc.

This plugin uses a custom `NotificationListenerService` implemented natively in Kotlin for more reliable and maintainable functionality than older packages.

---

## 🔧 Features

- ✅ Read notifications (title, text, package name, etc.)
- 📤 Send smart replies to compatible notifications
- 🚀 Custom implementation — not dependent on unmaintained packages
- 🔐 Does **not** require intrusive permissions — just Notification Access

---

## 📦 Installation

In your `pubspec.yaml`:

```yaml
dependencies:
  smart_notification_listener:
    path: ../smart_notification_listener  # Use path for local testing or replace with Git URL
```
---

## 📱 Android Setup
# 1. Add required permissions in AndroidManifest.xml
In android/app/src/main/AndroidManifest.xml, add the following inside the <manifest> tag:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

# 2. Register the service
Inside the <application> tag, add:

```xml
<service
    android:name="im.zoe.labs.smart_notification_listener.SmartNotificationListenerService"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

# 3. Enable Kotlin (only if not already enabled)
Ensure Kotlin is set up in your app. If you're using a recent version of Flutter and the Android Gradle Plugin, Kotlin is likely already enabled.

A. If using the older Gradle setup (build.gradle):
```buildscript {
    ext.kotlin_version = '1.9.0' // Or newer
    dependencies {
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

B. If using the modern Gradle setup (plugins block):
Make sure your android/build.gradle or settings.gradle includes:

```plugins {
    id 'org.jetbrains.kotlin.android' version '1.9.0' apply false
}
```
And in your app/build.gradle:

```
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
```


## 🧪 Example Usage
```dart
import 'package:flutter/material.dart';
import 'package:smart_notification_listener/smart_notification_listener.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = SmartNotificationListener();
  bool _serviceRunning = false;
  final List<SmartNotification> _notifications = [];
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    _listenToNotifications();
  }

  @override
  void dispose() {
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initPlatformState() async {
    final isRunning = await _plugin.isNotificationServiceRunning();
    setState(() {
      _serviceRunning = isRunning;
    });
  }

  void _listenToNotifications() {
    _plugin.notifications.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
      });
    });
  }

  Future<void> _openSettings() async {
    await _plugin.openNotificationSettings();
  }

  Future<void> _sendReply(String id, String message) async {
    final success =
        await _plugin.sendReply(id: id, message: message);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Reply sent!" : "Failed to send reply")),
    );
  }

  Future<void> _startService() async {
    final success = await _plugin.startNotificationService();
    setState(() => _serviceRunning = success);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to start service")),
      );
    }
  }

  Future<void> _stopService() async {
    final success = await _plugin.stopNotificationService();
    setState(() => _serviceRunning = !success);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to stop service")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Notification Listener Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Notification Listener')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Notification Service Running: $_serviceRunning'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openSettings,
                child: const Text("Open Notification Settings"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _serviceRunning ? null : _startService,
                      child: const Text("Start Service"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _serviceRunning ? _stopService : null,
                      child: const Text("Stop Service"),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text("Received Notifications:"),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final String notificationId = item.id;
                    if (item.hasReply == true) {
                      final controller = _replyControllers.putIfAbsent(
                        notificationId,
                        () => TextEditingController(),
                      );
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(item.package),
                            subtitle: Text('${item.title}: ${item.text}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Type a reply...',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () {
                                    _sendReply(notificationId, controller.text);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    } else {
                      return ListTile(
                        title: Text(item.package),
                        subtitle: Text('${item.title}: ${item.text}'),
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🛠 Available Methods

| Method                             | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| `startNotificationService()`       | Starts the background notification listener service         |
| `stopNotificationService()`        | Stops the service                                           |
| `isNotificationServiceRunning()`   | Returns whether the service is currently active             |
| `openNotificationSettings()`       | Opens Android's Notification Listener Settings screen       |
| `notifications`                    | Stream of received notification events                      |
| `sendReply({id, message})`         | Sends a reply to the specified notification                 |

## 📋 Example Notification Payload
```json :
  {
    "id": "com.whatsapp-1698754310000",
    "package": "com.whatsapp",
    "title": "John Doe",
    "text": "Hey! How are you?",
    "hasReply": true,
    "receivedAt": "2025-07-31T14:42:30.123Z"
  }
```

# 🧠 Notes
## Works on Android only (API 21+)
- Notifications must have reply action support to be used with sendReply
- Ensure notification access is granted manually from device settings