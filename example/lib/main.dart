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
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _init();
    _listenNotifications();
  }

  // ---------------------------------------
  // INIT: Check permission + service status
  // ---------------------------------------
  Future<void> _init() async {
    final perm = await plugin.hasPermission();
    final running = await plugin.isNotificationServiceRunning();
    setState(() {
      _hasPermission = perm;
      _isServiceRunning = running && perm;
    });
  }

  // ---------------------------------------
  // Listen to notifications
  // ---------------------------------------
  void _listenNotifications() {
    plugin.notifications.listen((notification) {
      // Ignore keyboard service internal notifications
      if (notification.packageName == 'android') return;
      setState(() {
        _notifications.insert(0, notification);
      });
    });
  }

  // ---------------------------------------
  // Toggle start/stop
  // ---------------------------------------
  Future<void> _toggleService() async {
    // Enforce permission
    final perm = await plugin.hasPermission();
    if (!perm) {
      await plugin.openNotificationSettings();
      return;
    }
    if (_isServiceRunning) {
      await plugin.stopNotificationService();
    } else {
      await plugin.startNotificationService();
    }
    await _init();
  }

  // ---------------------------------------
  // Send reply
  // ---------------------------------------
  Future<void> _sendReply(SmartNotification notification, String message) async {
    try {
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
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------
  // Notification Card UI
  // ---------------------------------------
  Widget _buildNotificationCard(SmartNotification n) {
    final TextEditingController controller = TextEditingController();
    final actionInfo = n.actions.isNotEmpty ? n.actions.first : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.packageName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              n.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(n.text),
            if (n.canReply && actionInfo != null && actionInfo.inputs.isNotEmpty)
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
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------
  // BUILD UI
  // ---------------------------------------
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
              await _init(); // re-check after returning
            },
          ),
        ],
      ),

      body: !_hasPermission
        ? const Center(
            child: Text(
              "Permission not granted.\nPlease enable Notification Access.",
              textAlign: TextAlign.center,
            ),
          )
        : _notifications.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) =>
                  _buildNotificationCard(_notifications[index]),
            ),
  );
  }
}
