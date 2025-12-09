package com.ronak.smart_notification_listener

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Handles communication between the Background Service and the Flutter UI.
 * It implements a buffering mechanism to save notifications when the UI is closed.
 */
object NotificationHelper {
    private var eventSink: EventChannel.EventSink? = null

    // Thread-safe buffer for notifications received while Flutter is disconnected
    private val eventQueue = ConcurrentLinkedQueue<Any>()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setSink(sink: EventChannel.EventSink?) {
        mainHandler.post {
            eventSink = sink
            if (sink != null) {
                Log.d("NLS", "✅ Sink attached. Flushing ${eventQueue.size} buffered events.")
                flushQueue()
            } else {
                Log.d("NLS", "🔌 Sink detached. Buffering events.")
            }
        }
    }

    private fun flushQueue() {
        // Drain the queue and send all old events to the newly connected UI
        while (!eventQueue.isEmpty()) {
            val event = eventQueue.poll()
            if (event != null) {
                try {
                    eventSink?.success(event)
                } catch (e: Exception) {
                    Log.e("NLS", "Error sending buffered event: ${e.message}")
                    // If sending fails, connection is likely dead. Stop flushing to preserve order.
                    break 
                }
            }
        }
    }

    fun sendEvent(data: Any) {
        // MethodChannel/EventChannel must always be accessed on the Main Thread
        mainHandler.post {
            if (eventSink != null) {
                try {
                    Log.d("NLS", "🚀 Sending to Flutter: $data") // <--- ADD THIS
                    eventSink?.success(data)
                } catch (e: Exception) {
                    Log.w("NLS", "Sink failed, switching to buffer: ${e.message}")
                    eventSink = null
                    addToBuffer(data)
                }
            } else {
                Log.d("NLS", "⚠️ Sink is NULL. Buffering event.") // <--- ADD THIS
                addToBuffer(data)
            }
        }
    }

    private fun addToBuffer(data: Any) {
        // Limit buffer size to prevent OutOfMemory errors if app is closed for a long time
        if (eventQueue.size >= 100) {
            eventQueue.poll() // Remove oldest to prevent OOM
        }
        eventQueue.offer(data)
    }
}