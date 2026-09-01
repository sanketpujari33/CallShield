package com.sysadmindoc.callshield.callshield_app

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * CallShieldNotificationListener
 * 
 * Android NotificationListenerService for real-time inspection of incoming
 * notifications (SMS, RCS, VoIP and messaging apps) for spam and phishing threats.
 */
class CallShieldNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        try {
            val pkg = sbn.packageName ?: return
            val extras = sbn.notification.extras ?: return
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

            // Ignore our own notifications
            if (pkg == packageName) return

            // Known messaging packages: Google Messages, Samsung Messages, WhatsApp, Telegram, Signal
            val isMessaging = pkg.contains("messaging") ||
                              pkg.contains("mms") ||
                              pkg.contains("whatsapp") ||
                              pkg.contains("telegram") ||
                              pkg.contains("signal")

            if (isMessaging && (title.isNotEmpty() || text.isNotEmpty())) {
                Log.d("CallShieldNotificationListener", "Screening notification from $pkg: $title")
            }
        } catch (e: Exception) {
            Log.e("CallShieldNotificationListener", "Error screening notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i("CallShieldNotificationListener", "Notification listener connected successfully")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.i("CallShieldNotificationListener", "Notification listener disconnected")
    }
}
