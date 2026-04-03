package com.ronak.smart_notification_listener

import android.app.Notification
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.app.RemoteInput
import android.content.Context
import android.content.ComponentName
import android.service.notification.NotificationListenerService as AndroidNotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : AndroidNotificationListenerService() {

    companion object {
        var isRunning: Boolean = false
        private var instance: NotificationListener? = null

        // Static helper to reply to notifications
        // This simulates a user typing into the "Quick Reply" text field of a notification.
        fun sendReply(id: String, message: String): Boolean {

            val service = instance ?: return false

            // 1. Find the active notification by its unique Key
            val sbn = service.activeNotifications?.find { it.key == id } ?: return false
            
            // 2. Search for the specific Action that allows Free Form Input (Text Reply)
            val actions = sbn.notification.actions ?: return false
            val replyAction = actions.find { action ->
                action.remoteInputs?.any { it.allowFreeFormInput } == true
            } ?: return false

            val remoteInput = replyAction.remoteInputs?.firstOrNull() ?: return false
            
            // 3. Create a Bundle containing the user's message
            val bundle = Bundle().apply {
                putCharSequence(remoteInput.resultKey, message)
            }

            // 4. Create an Intent and inject the RemoteInput results
            val intent = Intent()
            RemoteInput.addResultsToIntent(arrayOf(remoteInput), intent, bundle)

            // 5. Fire the PendingIntent. This sends the data back to the original app (e.g., WhatsApp).
            return try {
                replyAction.actionIntent.send(service, 0, intent)
                true
            } catch (e: Exception) {
                Log.e("NLS", "Reply failed: ${e.message}")
                false
            }
        }
        
        // A hack to force the Android OS to restart the service if it gets killed or stuck.
        // It briefly disables and re-enables the component setting.
        fun forceReconnect(context: Context) {
            val pm = context.packageManager
            val componentName = ComponentName(context, NotificationListener::class.java)
            // Toggle the component state to force system to restart service
            pm.setComponentEnabledSetting(componentName, 
                android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
                android.content.pm.PackageManager.DONT_KILL_APP)
            pm.setComponentEnabledSetting(componentName, 
                android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
                android.content.pm.PackageManager.DONT_KILL_APP)
        }

        /**
         * Asks the system to bind the notification listener (API 24+).
         * On older APIs, falls back to [forceReconnect].
         */
        fun requestBind(context: Context) {
            val component = ComponentName(context, NotificationListener::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                AndroidNotificationListenerService.requestRebind(component)
            } else {
                forceReconnect(context)
            }
        }

        /** Requests unbind while the service is connected (API 24+ only). */
        fun requestUnbindIfBound(): Boolean {
            val service = instance ?: return false
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
            return try {
                // Stubs may expose void or boolean; treat no exception as success.
                service.requestUnbind()
                true
            } catch (e: Exception) {
                Log.e("NLS", "requestUnbind failed: ${e.message}")
                false
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        isRunning = true
        // Log.d("NLS", "Service Connected")
        NotificationHelper.sendEvent("connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        instance = null
        isRunning = false
        // Log.d("NLS", "Service Disconnected")
        NotificationHelper.sendEvent("disconnected")
    }

    // Triggered by the OS whenever a new notification arrives
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // Log.d("NLS", "🔔 OS POSTED NOTIFICATION: ${sbn?.packageName}")
        if (sbn == null) return
        
        
        // Skip ongoing/process events if needed, but for now capture all
        val notification = sbn.notification ?: return
        val extras = notification.extras
        
        // Extract Data safely
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val packageName = sbn.packageName

        // Parse Actions to check for "Reply" capabilities
        val actionsList = ArrayList<Map<String, Any>>()
        notification.actions?.forEach { action ->
            val inputs = ArrayList<String>()
            action.remoteInputs?.forEach { inputs.add(it.resultKey) }
            actionsList.add(mapOf(
                "title" to (action.title?.toString() ?: ""),
                "inputs" to inputs,
                "isReplyAction" to (inputs.isNotEmpty())
            ))
        }

        // Format Date manually to ensure consistency across locales
        val dateFormat = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.US)
        val dateString = dateFormat.format(java.util.Date(sbn.postTime))

        val data = mapOf(
            "id" to sbn.key,
            "packageName" to sbn.packageName,
            "title" to title,
            "text" to text,
            "receivedAtFormatted" to dateString, // <--- CHANGED THIS
            "actions" to actionsList,
            "canReply" to actionsList.any { it["isReplyAction"] as Boolean }
        )

        NotificationHelper.sendEvent(data)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Optional: Send removal event if needed in the future
    }
}