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

        fun sendReply(
            id: String,
            message: String,
            context: Context,
            actionKey: String? = null
        ): Boolean {
            try {
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
                Log.e("NotificationListener", "sendReply error: ${e.message}", e)
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
        Log.d("NotificationListener", "Service created")
        serviceInstance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceInstance = null
    }

    override fun onNotificationPosted (sbn: StatusBarNotification) {
        // NEW: Hard stop if disabled
        if (!isEnabled) {
            Log.d("NotificationListener", "Service disabled — ignoring notification.")
            return
        }

        try {
            val extras = sbn.notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

            val actions = extractActions(sbn.notification, sbn.packageName, sbn.key)
            val utcFormatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }

            val map = mapOf(
                "packageName" to sbn.packageName,
                "id" to sbn.key,
                "title" to title,
                "text" to text,
                "canReply" to actions.any { it.isReplyAction },
                "receivedAtFormatted" to utcFormatter.format(Date()),
                "extras" to extras.keySet().associateWith { extras[it]?.toString() ?: "" },
                "actions" to actions.map {
                    mapOf(
                        "actionId" to it.actionId,
                        "title" to it.title,
                        "inputs" to it.inputs,
                        "isReplyAction" to it.isReplyAction
                    )
                }
            )

            eventSink?.success(map)
            Log.d("NotificationListener", "Notification posted: $map")
        } catch (e: Exception) {
            Log.e("NotificationListener", "onNotificationPosted error: ${e.message}", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // optional: notify Flutter about removals
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d("NotificationListener", "Listener connected")
        serviceInstance = this
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d("NotificationListener", "Listener disconnected")
        serviceInstance = null
    }
}
