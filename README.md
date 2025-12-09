# Smart Notification Listener

A robust Flutter plugin for Android that allows your app to **listen to system notifications** in real-time and **send replies directly** to supported apps like WhatsApp, Telegram, and more.

This plugin uses a custom Native Kotlin implementation to handle Android's `NotificationListenerService`, offering better reliability and connection recovery than older packages.

---

## 🔧 Features

- ✅ **Real-time Listening:** Capture title, text, package name, and large icons.
- 📤 **Smart Replies:** Reply directly to notifications that support input (e.g., messaging apps).
- 🔄 **Auto-Reconnect:** Includes tools to force-restart the service if Android kills it.
- 🏥 **Health Monitoring:** Detect connection status and recover automatically.
- 🔐 **Privacy Focused:** Requires only Notification Access, no intrusive permissions.

---

## 📦 Installation

In your `pubspec.yaml`:

```yaml
dependencies:
  smart_notification_listener:
    path: ../smart_notification_listener  # Use path for local testing or Git URL
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
```
buildscript {
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
import 'dart:async';
import 'dart:developer'; // For log()
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SmartNotificationListener _plugin = SmartNotificationListener();
  StreamSubscription<SmartNotification>? _subscription;
  
  String _status = "Idle";
  String _lastNotification = "None";
  bool _isHealthy = false;
  Timer? _healthMonitorTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-start listening on launch
    startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _healthMonitorTimer?.cancel();
    super.dispose();
  }

  // Handle App Lifecycle: Reconnect when app comes to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log("🔄 App Resumed - Refreshing connection...");
      startListening();
    }
  }

  void startListening() {
    // 1. Cancel old subscription
    _subscription?.cancel();
    
    // 2. Listen to stream
    _subscription = _plugin.notifications.listen((event) {
      // Handle Control Signals (Native side sends 'connected' on service start)
      if (event.packageName == 'connected') {
        setState(() {
          _status = "Connected ✅";
          _isHealthy = true;
        });
        return;
      }
      
      // Handle Actual Notifications
      setState(() {
        _lastNotification = "${event.title}: ${event.text}";
      });
    });

    // 3. Start Health Monitor
    _startHealthMonitor();
  }

  /// Checks if the service is running and forces a reconnect if needed
  void _startHealthMonitor() {
    _healthMonitorTimer?.cancel();
    int checks = 0;
    
    _healthMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      checks++;
      // Stop checking after 30s or if connection is established
      if (checks > 30 || _isHealthy) { 
        timer.cancel();
        return;
      }

      bool hasPermission = await _plugin.hasPermission();
      // If we have permission but no connection signal, kick the service
      if (hasPermission && !_isHealthy) {
        log("⚡ Health Monitor: Kicking Service...");
        await _plugin.forceReconnect();
      }
    });
  }

  Future<void> requestPermissions() async {
    // Start monitor BEFORE going to settings so we catch the connection on return
    _startHealthMonitor();
    await _plugin.openNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Notification Listener')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Last Notification:', style: TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_lastNotification, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: requestPermissions,
                child: const Text('Grant Permissions / Fix Connection'),
              ),
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
| `startNotificationService()`       | Commands the background service to start.        |
| `stopNotificationService()`        | Stops the background service.                                           |
| `isNotificationServiceRunning()`   | Returns true if the service is currently active.             |
| `forceReconnect()`   | Crucial: Toggles the component state to force Android to restart the service (fixes "silent kills").             |
| `openNotificationSettings()`       | Opens Android's Notification Access settings screen.       |
| `hasPermission()`                    | Checks if Notification Access is granted.                      |
| `notifications`                    | A Stream<SmartNotification> of incoming events.                      |
| `sendReply(notification obj, message)`         | Sends a reply to a notification (requires the notification object and message).                 |

## 📋 Example Notification Payload
```json :
  {
    "id": "0|com.whatsapp|1|...",
    "packageName": "com.whatsapp",
    "title": "John Doe",
    "text": "Hello world!",
    "receivedAt": "2025-11-20 09:38:27",
    "canReply": true,
    "actions": [
      {
        "title": "Reply",
        "inputs": ["reply_key"] 
      }
    ]
  }
```

# 🧠 Notes
- Android Only: This plugin works on Android API 21+.
- Lifecycle: Android aggressively kills background services. The forceReconnect() method and the health monitor pattern shown in the example are highly recommended to ensure your app stays connected.
- Permissions: You cannot programmatically grant Notification Access. You must direct the user to the settings screen using openNotificationSettings().