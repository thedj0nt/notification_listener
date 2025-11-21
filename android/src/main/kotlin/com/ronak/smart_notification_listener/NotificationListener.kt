package com.ronak.smart_notification_listener

import android.app.Notification
import android.app.RemoteInput
import android.content.Intent
import android.content.Context
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.Date
import android.os.Handler
import android.os.Looper


data class NotificationAction(
    val actionId: String,
    val title: String,
    val inputs: List<String>,
    val isReplyAction: Boolean
)

class NotificationListener : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        var serviceInstance: NotificationListener? = null
        var isEnabled: Boolean = false
        var includeExtras: Boolean = false

        fun sendReply(
            id: String,
            message: String,
            context: Context,
            actionKey: String? = null
        ): Boolean {
            try {
                 // --- Validate input ---
                if (id.isBlank()) return false
                if (message.isBlank()) return false

                // Security & stability: prevent extremely large replies that may crash messaging apps via RemoteInput
                if (message.length > 2000) return false

                // Safety check: actionKey should be short; long values may indicate misuse or malformed input
                if (actionKey != null && actionKey.length > 200) return false

                val sbn = serviceInstance?.activeNotifications?.find { it.key == id }
                if (sbn != null) {
                    val actions = sbn.notification.actions ?: return false

                    // Pick target action
                    val targetAction = if (actionKey != null) {
                        // match by title or remoteInput resultKey
                        actions.firstOrNull { action ->
                            action.title?.toString() == actionKey ||
                            action.remoteInputs?.any { ri -> ri.resultKey == actionKey } == true
                        }
                    } else {
                        // fallback: first action with free-form input
                        actions.firstOrNull { action ->
                            action.remoteInputs?.any { ri -> ri.allowFreeFormInput } == true
                        }
                    }

                    if (targetAction != null) {
                        val remoteInput = targetAction.remoteInputs?.firstOrNull() ?: return false

                        val bundle = Bundle().apply {
                            putCharSequence(remoteInput.resultKey, message)
                        }

                        val fillInIntent = Intent()
                        RemoteInput.addResultsToIntent(arrayOf(remoteInput), fillInIntent, bundle)

                        targetAction.actionIntent.send(context, 0, fillInIntent)
                        return true
                    }
                }
            } catch (e: Exception) {
                // Log.e("NotificationListener", "sendReply error: ${e.message}", e)
            }
            return false
        }

        fun extractActions(notification: Notification?, packageName: String, key: String): List<NotificationAction> {
            val actions = mutableListOf<NotificationAction>()
            try {
                notification?.actions?.forEachIndexed { index, action ->
                    val inputs = mutableListOf<String>()
                    var isReply = false
                    action.remoteInputs?.forEach { ri ->
                        inputs.add(ri.resultKey)
                        if (ri.allowFreeFormInput) isReply = true
                    }
                    actions.add(
                        NotificationAction(
                            actionId = "${key}_$index",
                            title = action.title?.toString() ?: "",
                            inputs = inputs,
                            isReplyAction = isReply
                        )
                    )
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "extractActions error: ${e.message}", e)
            }
            return actions
        }
    }

    override fun onCreate() {
        super.onCreate()
        // Log.d("NotificationListener", "Service created")
        serviceInstance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceInstance = null
    }

    override fun onNotificationPosted (sbn: StatusBarNotification) {
        // NEW: Hard stop if disabled
        if (!isEnabled) {
            // Log.d("NotificationListener", "Service disabled — ignoring notification.")
            return
        }

        try {
            val extras = sbn.notification.extras
            
            // Basic fields (sanitized/truncated)
            val rawTitle = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val rawText  = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

            // Truncate to safe lengths to avoid flooding / crashes
            val title = rawTitle.take(500)   // titles are usually short
            val text  = rawText.take(2000)   // protect against extremely long notifications

            val actions = extractActions(sbn.notification, sbn.packageName, sbn.key)
            val utcFormatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }

            // Optionally include extras — disabled by default for privacy
            // val safeExtras: Map<String, String> = if (includeExtras) {
            //    try {
            //        extras.keySet().associateWith { key ->
            //            val v = extras[key]?.toString() ?: ""
            //            // truncate individual extra values to a safe length
            //            v.take(2000)
            //       }
            //    } catch (_: Exception) {
            //        emptyMap()
            //    }
            // } else {
            //   emptyMap()
            // }

            val map = mapOf(
                "packageName" to sbn.packageName,
                "id" to sbn.key,
                "title" to title,
                "text" to text,
                "canReply" to actions.any { it.isReplyAction },
                "receivedAtFormatted" to utcFormatter.format(Date()),
                // "extras" to safeExtras, // uncomment this when extra info is needed
                "actions" to actions.map {
                    mapOf(
                        "actionId" to it.actionId,
                        "title" to it.title,
                        "inputs" to it.inputs,
                        "isReplyAction" to it.isReplyAction
                    )
                }
            )

            // Deliver event on main thread (safe for EventChannel)
            Handler(Looper.getMainLooper()).post {
                try {
                    eventSink?.success(map)
                } catch (e: Exception) {
                    // debug-only logging — do not log sensitive data in release
                    // Log.e("NotificationListener", "eventSink.success failed: ${e.message}", e)
                }
            }

            // uncomment this only for debugging
            // Log.d("NotificationListener", "Notification posted: $map")
        } catch (e: Exception) {
            Log.e("NotificationListener", "onNotificationPosted error: ${e.message}", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // optional: notify Flutter about removals
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        // Log.d("NotificationListener", "Listener connected")
        serviceInstance = this
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        // Log.d("NotificationListener", "Listener disconnected")
        serviceInstance = null
    }
}
