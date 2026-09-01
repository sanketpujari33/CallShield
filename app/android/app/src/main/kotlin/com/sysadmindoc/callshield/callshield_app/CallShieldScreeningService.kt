package com.sysadmindoc.callshield.callshield_app

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class CallShieldScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val handle = callDetails.handle
        val rawNumber = handle?.schemeSpecificPart ?: ""

        if (rawNumber.isEmpty()) {
            // Unknown or restricted caller
            respondToCall(callDetails, CallResponse.Builder().build())
            return
        }

        // Fast on-device screening logic
        val isSpam = evaluateQuickSpam(rawNumber)

        if (isSpam) {
            val response = CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(true)
                .build()

            respondToCall(callDetails, response)
        } else {
            respondToCall(callDetails, CallResponse.Builder().build())
        }
    }

    private fun evaluateQuickSpam(number: String): Boolean {
        val digits = number.filter { it in '0'..'9' }
        // Fast checks: Caribbean Wangiri prefixes, toll free abuse, or 555 exchange
        if (digits.length == 11 && digits.startsWith("1")) {
            val npa = digits.substring(1, 4)
            val nxx = digits.substring(4, 7)
            if (npa in listOf("809", "829", "849", "876", "284", "473") || nxx == "555") {
                return true
            }
        }
        return false
    }
}
