package com.example.smart_notification_listener

import android.app.Notification
import android.app.PendingIntent
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.RemoteInput
import io.flutter.plugin.common.EventChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        var isEnabled: Boolean = true
        private var serviceInstance: NotificationListener? = null

        private const val MAX_STORE_SIZE = 1000
        private val notificationStore = mutableListOf<StoredNotification>()
        private val pendingEvents = mutableListOf<Map<String, Any?>>()

        var eventSink: EventChannel.EventSink? = null
            set(value) {
                field = value
                flushPendingEvents()
            }

        @JvmStatic
        fun sendReply(id: String, message: String): Boolean {
            val context = serviceInstance ?: return false

            val storedNotification = synchronized(notificationStore) {
                notificationStore.find { it.id == id }
            } ?: return false

            val sbn = storedNotification.sbn
            val actions = sbn.notification.actions ?: return false

            for (action in actions) {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT_WATCH) {
                    val originalInputs = action.remoteInputs ?: continue
                    val convertedInputs = originalInputs.map { convertRemoteInput(it) }.toTypedArray()

                    val results = Bundle().apply {
                        putCharSequence(convertedInputs[0].resultKey, message)
                    }

                    val fillInIntent = Intent().apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        RemoteInput.addResultsToIntent(
                            convertedInputs,
                            this,
                            results
                        )
                    }

                    return try {
                        action.actionIntent.send(context, 0, fillInIntent)
                        true
                    } catch (e: PendingIntent.CanceledException) {
                        e.printStackTrace()
                        false
                    }
                }
            }

            return false
        }

        private fun convertRemoteInput(input: android.app.RemoteInput): RemoteInput {
            return RemoteInput.Builder(input.resultKey)
                .setLabel(input.label)
                .setChoices(input.choices)
                .setAllowFreeFormInput(input.allowFreeFormInput)
                .addExtras(input.extras)
                .build()
        }

        private fun flushPendingEvents() {
            synchronized(pendingEvents) {
                eventSink?.let { sink ->
                    Log.d("NotificationListener", "Flushing ${pendingEvents.size} pending events")
                    pendingEvents.forEach { sink.success(it) }
                    pendingEvents.clear()
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        serviceInstance = this
    }

    override fun onDestroy() {
        serviceInstance = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: "No Title"
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "No Text"

        var hasReply = false
        sbn.notification.actions?.forEach { action ->
            action.remoteInputs?.forEach { remoteInput ->
                if (remoteInput.allowFreeFormInput) {
                    hasReply = true
                }
            }
        }

        val id = sbn.key
        val stored = StoredNotification(
            id = id,
            sbn = sbn,
            packageName = pkg,
            title = title,
            text = text,
            hasReply = hasReply
        )

        synchronized(notificationStore) {
            notificationStore.add(stored)
            if (notificationStore.size > MAX_STORE_SIZE) {
                notificationStore.removeAt(0)
            }
        }

        val data = mapOf(
            "id" to id,
            "package" to pkg,
            "title" to title,
            "text" to text,
            "hasReply" to hasReply
        )

        if (eventSink != null) {
            Log.d("NotificationListener", "Sending notification to Flutter: $data")
            eventSink?.success(data)
        } else {
            Log.w("NotificationListener", "Flutter is not listening yet. Buffering: $data")
            synchronized(pendingEvents) {
                pendingEvents.add(data)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        if (!isEnabled) return

        val key = sbn.key
        synchronized(notificationStore) {
            notificationStore.removeAll { it.id == key }
        }

        Log.d("NotificationListener", "Notification removed: $key")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d("NotificationListener", "Notification listener connected")
        serviceInstance = this
    }
}

data class StoredNotification(
    val id: String,
    val sbn: StatusBarNotification,
    val packageName: String,
    val title: String?,
    val text: String?,
    val hasReply: Boolean
)
