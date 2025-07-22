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
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    tools:ignore="ProtectedPermissions" />
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

# 3. Enable Kotlin (if not already enabled)
In android/build.gradle:

```gradle
buildscript {
    ext.kotlin_version = '1.9.0' // or higher
    ...
}
```
And in android/app/build.gradle:

```gradle
apply plugin: 'kotlin-android'
```


## 🧪 Example Usage
```dart
import 'package:flutter/material.dart';
import 'package:smart_notification_listener/smart_notification_listener.dart';

void main() {
  runApp(const MyApp());}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();}

class _MyAppState extends State<MyApp> {
  final _plugin = SmartNotificationListener();
  final List<Map<dynamic, dynamic>> _notifications = [];
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _plugin.notifications.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
      })
    });
  }

  Future<void> _sendReply(String id, String message) async {
    final success = await _plugin.sendReply(id: id, message: message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Reply sent!" : "Failed to send reply")),
    );}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Notification Listener Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Notification Listener')),
        body: ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final controller = _replyControllers.putIfAbsent(
              item['id'],
              () => TextEditingController(),
            );
            return ListTile(
              title: Text('${item['title']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['text']}'),
                  if (item['hasReply'] == true)
                    Row(
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
                          onPressed: () => _sendReply(item['id'], controller.text),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```


🛠 Available Methods
```
Method	                          Description
startNotificationService()	        Starts the foreground notification listener service
stopNotificationService()	          Stops the service
isNotificationServiceRunning()	    Returns whether the service is currently running
openNotificationSettings()	        Opens the Android Notification Listener Settings screen
notifications	Stream of received notification events
sendReply({required String id, required String message})	Sends a reply to the given notification
```

📋 Example Notification Payload
```json :
  {
    "id": "com.whatsapp-1698754310000",
    "package": "com.whatsapp",
    "title": "John Doe",
    "text": "Hey! How are you?",
    "hasReply": true
  }
```