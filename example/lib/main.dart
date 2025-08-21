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
