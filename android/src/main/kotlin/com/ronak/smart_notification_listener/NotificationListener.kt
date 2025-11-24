package com.ronak.smart_notification_listener

import android.app.Notification
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.*

data class NotificationAction(
    val actionId: String,
    val title: String,
    val inputs: List<String>,
    val isReplyAction: Boolean
)

class NotificationListener : NotificationListenerService() {

    companion object {
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        @Volatile
        private var serviceInstance: NotificationListener? = null

        fun getServiceInstance(): NotificationListener? = serviceInstance

        var isEnabled: Boolean = false
        var includeExtras: Boolean = false

        fun sendReply(
            id: String,
            message: String,
            context: Context,
            actionKey: String? = null
        ): Boolean {
            try {
                if (id.isBlank() || message.isBlank() || message.length > 2000) return false
                if (actionKey != null && actionKey.length > 200) return false

                val instance = serviceInstance ?: return false
                val sbn = instance.activeNotifications?.find { it.key == id } ?: return false
                val actions = sbn.notification.actions ?: return false

                val targetAction = if (actionKey != null) {
                    actions.firstOrNull { action ->
                        action?.title?.toString() == actionKey ||
                        action?.remoteInputs?.any { ri -> ri?.resultKey == actionKey } == true
                    }
                } else {
                    actions.firstOrNull { action ->
                        action?.remoteInputs?.any { ri -> ri?.allowFreeFormInput == true } == true
                    }
                } ?: return false

                val remoteInput = targetAction.remoteInputs?.firstOrNull() ?: return false

                val bundle = Bundle().apply {
                    putCharSequence(remoteInput.resultKey, message)
                }

                val fillInIntent = Intent()
                RemoteInput.addResultsToIntent(arrayOf(remoteInput), fillInIntent, bundle)

                targetAction.actionIntent?.send(context, 0, fillInIntent)
                return true
            } catch (_: Exception) {
                return false
            }
        }

        fun extractActions(notification: Notification?, key: String): List<NotificationAction> {
            val actionsList = mutableListOf<NotificationAction>()
            try {
                notification?.actions?.forEachIndexed { index, action ->
                    val inputs = mutableListOf<String>()
                    var isReply = false
                    action?.remoteInputs?.forEach { ri ->
                        ri?.resultKey?.let { inputs.add(it) }
                        if (ri?.allowFreeFormInput == true) isReply = true
                    }
                    actionsList.add(
                        NotificationAction(
                            actionId = "${key}_$index",
                            title = action?.title?.toString() ?: "",
                            inputs = inputs,
                            isReplyAction = isReply
                        )
                    )
                }
            } catch (_: Exception) { }
            return actionsList
        }
    }

    override fun onCreate() {
        super.onCreate()
        serviceInstance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceInstance = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        try {
            if (!isEnabled || sbn == null) return

            val notification = sbn.notification ?: return
            val extras = notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.take(500) ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.take(2000) ?: ""

            val actions = extractActions(notification, sbn.key)
            val utcFormatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }

            val map = mutableMapOf<String, Any>(
                "packageName" to sbn.packageName,
                "id" to sbn.key,
                "title" to title,
                "text" to text,
                "canReply" to actions.any { it.isReplyAction },
                "receivedAtFormatted" to utcFormatter.format(Date()),
                "actions" to actions.map {
                    mapOf(
                        "actionId" to it.actionId,
                        "title" to it.title,
                        "inputs" to it.inputs,
                        "isReplyAction" to it.isReplyAction
                    )
                }
            )

            Handler(Looper.getMainLooper()).post {
                try {
                    eventSink?.success(map)
                } catch (_: Exception) { }
            }

        } catch (_: Exception) { }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        serviceInstance = this
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        serviceInstance = null
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) { }
}
