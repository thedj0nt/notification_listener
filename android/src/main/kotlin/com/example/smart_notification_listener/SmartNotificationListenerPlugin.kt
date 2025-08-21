package com.example.smart_notification_listener

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmartNotificationListenerPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "smart_notification_listener")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "smart_notification_listener_event")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isNotificationServiceRunning" -> {
                result.success(NotificationListener.serviceInstance != null)
            }

            "startNotificationService" -> {
                val intent = Intent(context, NotificationListener::class.java)
                context.startService(intent)
                result.success(true)
            }

            "stopNotificationService" -> {
                val intent = Intent(context, NotificationListener::class.java)
                context.stopService(intent)
                result.success(true)
            }

            "restartNotificationService" -> {
                val intent = Intent(context, NotificationListener::class.java)
                context.stopService(intent)
                context.startService(intent)
                result.success(true)
            }

            "openNotificationSettings" -> {
                try {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS").apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to open notification settings: ${e.message}", null)
                }
            }

            "sendReply" -> {
                val id = call.argument<String>("id")
                val message = call.argument<String>("message")
                val actionKey = call.argument<String>("actionKey")

                if (id != null && message != null) {
                    val success = NotificationListener.sendReply(id, message, context, actionKey)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENTS", "id and message are required", null)
                }
            }


            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        NotificationListener.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        NotificationListener.eventSink = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
