package com.sysadmindoc.callshield.callshield_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages: Array<SmsMessage>? = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            val sender = messages[0].displayOriginatingAddress ?: ""
            val fullBody = messages.joinToString("") { it.displayMessageBody ?: "" }

            // Phishing indicators detection
            val isSpam = isPhishingSms(fullBody)
            if (isSpam) {
                // Abort broadcast if highest priority receiver (blocking malicious SMS delivery)
                try {
                    abortBroadcast()
                } catch (_: Exception) {}
            }
        }
    }

    private fun isPhishingSms(body: String): Boolean {
        val lower = body.lowercase()
        val spamKeywords = listOf(
            "urgent action required",
            "account suspended",
            "unauthorized transaction",
            "click here to verify",
            "crypto giveaway",
            "claim your refund"
        )
        return spamKeywords.any { lower.contains(it) }
    }
}
