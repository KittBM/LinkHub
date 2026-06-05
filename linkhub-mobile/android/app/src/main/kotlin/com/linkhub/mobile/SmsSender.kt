package com.linkhub.mobile

import android.content.Context
import android.telephony.SmsManager

object SmsSender {
    fun send(context: Context, to: String, body: String) {
        try {
            @Suppress("DEPRECATION")
            val smsManager = SmsManager.getDefault()
            val parts = smsManager.divideMessage(body)
            smsManager.sendMultipartTextMessage(to, null, parts, null, null)
        } catch (_: Exception) {}
    }
}
