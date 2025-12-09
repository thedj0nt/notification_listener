package com.ronak.smart_notification_listener

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.content.ComponentName
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware // <--- IMPORT THIS
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmartNotificationListenerPlugin : FlutterPlugin, 
    MethodChannel.MethodCallHandler, 
    EventChannel.StreamHandler, 
    ActivityAware {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, "smart_notification_listener")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "smart_notification_listener_event")
        eventChannel.setStreamHandler(this)
    }

    // --- StreamHandler Implementation ---
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // Flutter is ready to receive data
        NotificationHelper.setSink(events)
    }

    override fun onCancel(arguments: Any?) {
        // Flutter stopped listening
        NotificationHelper.setSink(null)
    }

    // --- MethodCallHandler Implementation ---
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> {
                val enabledListeners = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
                val componentName = ComponentName(context, NotificationListener::class.java).flattenToString()
                result.success(enabledListeners?.contains(componentName) == true)
            }
            "openNotificationSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    // Fallback for devices that don't support the direct intent
                    try {
                        val intent = Intent(Settings.ACTION_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("ERROR", "Could not open settings", null)
                    }
                }
            }
            "isNotificationServiceRunning" -> result.success(NotificationListener.isRunning)
            "forceReconnect" -> {
                NotificationListener.forceReconnect(context)
                result.success(true)
            }
            "sendReply" -> {
                val id = call.argument<String>("id")
                val message = call.argument<String>("message")
                if (id != null && message != null) {
                    result.success(NotificationListener.sendReply(id, message))
                } else {
                    result.error("ARGS", "Missing id or message", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        NotificationHelper.setSink(null)
    }

    // --- ActivityAware Implementation (REQUIRED for onDetachedFromActivity) ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        // We don't need reference to activity for this plugin, 
        // but we can ensure the sink is ready if needed.
    }

    override fun onDetachedFromActivityForConfigChanges() {
        NotificationHelper.setSink(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        // No-op
    }

    override fun onDetachedFromActivity() {
        // IMPORTANT: When UI is gone, detach the sink so Helper starts buffering
        NotificationHelper.setSink(null)
    }
}