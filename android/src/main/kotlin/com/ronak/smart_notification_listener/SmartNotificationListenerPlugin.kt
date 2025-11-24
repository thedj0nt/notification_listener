package com.ronak.smart_notification_listener

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.content.ComponentName
import android.util.Log

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
                val instance = NotificationListener.getServiceInstance()
                result.success(instance != null && NotificationListener.isEnabled)
            }

            "startNotificationService" -> {
                NotificationListener.isEnabled = true
                try { 
                    context.startService(Intent(context, NotificationListener::class.java)) 
                } catch (_: Exception) {}
                result.success(true)
            }

            "stopNotificationService" -> {
                NotificationListener.isEnabled = false
                result.success(true)
            }

            "restartNotificationService" -> {
                NotificationListener.isEnabled = false
                Handler(Looper.getMainLooper()).postDelayed({
                    NotificationListener.isEnabled = true
                    try { context.startService(Intent(context, NotificationListener::class.java)) } catch (_: Exception) {}
                }, 300)
                result.success(true)
            }

            "openNotificationSettings" -> {
                try {
                    context.startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS").apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    })
                    result.success(true)
                } catch (e: Exception) { result.error("ERROR", e.message, null) }
            }

            "sendReply" -> {
                val id = call.argument<String>("id")
                val message = call.argument<String>("message")
                val actionKey = call.argument<String>("actionKey")
                if (id != null && message != null) {
                    result.success(NotificationListener.sendReply(id, message, context, actionKey))
                } else {
                    result.error("INVALID_ARGUMENTS", "id and message required", null)
                }
            }
            "hasPermission" -> {
                val enabledListeners = Settings.Secure.getString(
                    context.contentResolver,
                    "enabled_notification_listeners" // <-- FIXED
                ) ?: ""

                val componentName = ComponentName(context, NotificationListener::class.java)
                val flattened = componentName.flattenToString()

                Log.d("NL_DEBUG", "enabledListeners = $enabledListeners")
                Log.d("NL_DEBUG", "expected = $flattened")

                result.success(enabledListeners.contains(flattened))
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
