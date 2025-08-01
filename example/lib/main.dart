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
              // Text('Platform Version: $_platformVersion'),
              // const SizedBox(height: 8),
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
