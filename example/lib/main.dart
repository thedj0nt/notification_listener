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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log("🔄 App Resumed - Refreshing connection...");
      startListening();
    }
  }

  void startListening() {
    // 1. Cancel old
    _subscription?.cancel();
    
    // 2. Listen
    _subscription = _plugin.notifications.listen((event) {
      // Handle Control Signals
      if (event.packageName == 'connected') {
        setState(() {
          _status = "Connected ✅";
          _isHealthy = true;
        });
        return;
      }
      
      // Handle Notifications
      setState(() {
        _lastNotification = "${event.title}: ${event.text}";
      });
    });

    // 3. Start Health Monitor (The Fix)
    _startHealthMonitor();
  }

  void _startHealthMonitor() {
    _healthMonitorTimer?.cancel();
    int checks = 0;
    
    _healthMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      checks++;
      if (checks > 30 || _isHealthy) { // Stop after 30s or if healthy
        timer.cancel();
        return;
      }

      bool hasPermission = await _plugin.hasPermission();
      if (hasPermission && !_isHealthy) {
        log("⚡ Health Monitor: Kicking Service...");
        await _plugin.forceReconnect();
      }
    });
  }

  Future<void> requestPermissions() async {
    // Start monitor BEFORE going to settings
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
              Text('Last Notification:', style: const TextStyle(fontWeight: FontWeight.bold)),
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
