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
    android:name="com.ronak.smart_notification_listener.NotificationListener"
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Notification Listener Demo',
      home: const NotificationHomePage(),
    );
  }
}

class NotificationHomePage extends StatefulWidget {
  const NotificationHomePage({super.key});

  @override
  State<NotificationHomePage> createState() => _NotificationHomePageState();
}

class _NotificationHomePageState extends State<NotificationHomePage> {
  final SmartNotificationListener plugin = SmartNotificationListener();
  final List<SmartNotification> _notifications = [];
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _initService();
    _listenNotifications();
  }

  Future<void> _initService() async {
    final running = await plugin.isNotificationServiceRunning();
    setState(() {
      _isServiceRunning = running;
    });
  }

  void _listenNotifications() {
    plugin.notifications.listen((event) {
      final notification = event;
      // allow all notification expect the keyboard launch notification
      if (notification.packageName != 'android') {
        setState(() {
          _notifications.insert(0, notification);
        });
      }
    });
  }

  Future<void> _toggleService() async {
    if (_isServiceRunning) {
      await plugin.stopNotificationService();
    } else {
      await plugin.startNotificationService();
    }
    _initService();
  }

  Future<void> _sendReply(SmartNotification notification, String message) async {
    try {
      // pick the reply action from notification.actions
      final replyAction = notification.actions.firstWhere(
        (a) => a.isReplyAction,
        orElse: () => throw Exception("No reply action available"),
      );

      final success = await plugin.sendReply(
        notification: notification,
        message: message,
        action: replyAction,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Reply sent" : "Failed to send reply"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildNotificationCard(SmartNotification n) {
    final TextEditingController controller = TextEditingController();
    var actioninfo = n.actions.isNotEmpty ? n.actions.first : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.packageName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(n.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(n.text),
            n.canReply && n.actions.isNotEmpty && actioninfo != null && actioninfo.inputs.isNotEmpty ?
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Type a reply...",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          _sendReply(n, text);
                          controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              )
            : SizedBox(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Notification Listener"),
        actions: [
          IconButton(
            icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleService,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await plugin.openNotificationSettings();
            },
          ),
        ],
      ),
      body: _notifications.isEmpty
        ? const Center(child: Text("No notifications yet"))
        : ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(_notifications[index]);
            },
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
| `sendReply({notification obj, message})`         | Sends a reply to the specified notification                 |

## 📋 Example Notification Payload
```json :
  {
    "actions": List (3 items),
    "canReply": true,
    "extras": Map (24 items),
    "hashCode": 361357583,
    "id": "0|com.whatsapp|1|QtuX59btwVV1K1O5g51RABlhsSi56YwBH7oPhvel3gU",
    "packageName": "com.whatsapp",
    "receivedAt": "2025-11-20 09:38:27",
    "runtimeType": Type (SmartNotification),
    "text": "Hi, how are you?",
    "title": "+91 99999 99999",
  }
```

# 🧠 Notes
## Works on Android only (API 21+)
- Notifications must have reply action support to be used with sendReply
- Ensure notification access is granted manually from device settings