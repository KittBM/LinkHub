package com.linkhub.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class AgentTelecomReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var incomingNumber = ""

        fun performCallAction(context: Context, action: String) {
            when (action) {
                "reject" -> {
                    // Android 9+ requires ANSWER_PHONE_CALLS permission or TelecomManager
                    val intent = Intent(Intent.ACTION_CALL_PRIVILEGED)
                    // Use TelecomManager to end call
                    val tm = context.getSystemService(Context.TELECOM_SERVICE) as android.telecom.TelecomManager
                    try {
                        tm.endCall()
                    } catch (_: Exception) {}
                }
                "accept" -> {
                    val tm = context.getSystemService(Context.TELECOM_SERVICE) as android.telecom.TelecomManager
                    try {
                        tm.acceptRingingCall()
                    } catch (_: Exception) {}
                }
                "end" -> {
                    val tm = context.getSystemService(Context.TELECOM_SERVICE) as android.telecom.TelecomManager
                    try {
                        tm.endCall()
                    } catch (_: Exception) {}
                }
                "mute" -> {
                    val am = context.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                    am.isMicrophoneMute = true
                }
                "unmute" -> {
                    val am = context.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                    am.isMicrophoneMute = false
                }
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: ""

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                if (number.isNotEmpty()) incomingNumber = number
                if (lastState != TelephonyManager.CALL_STATE_RINGING) {
                    lastState = TelephonyManager.CALL_STATE_RINGING
                    notifyCallState("incoming", incomingNumber)
                }
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                lastState = TelephonyManager.CALL_STATE_OFFHOOK
                notifyCallState("active", incomingNumber)
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                if (lastState != TelephonyManager.CALL_STATE_IDLE) {
                    lastState = TelephonyManager.CALL_STATE_IDLE
                    notifyCallState("ended", incomingNumber)
                    incomingNumber = ""
                }
            }
        }
    }

    private fun notifyCallState(state: String, number: String) {
        val payload = JSONObject().apply {
            put("id", "call-${System.currentTimeMillis()}")
            put("phoneNumber", number)
            put("callerName", "")
            put("state", state)
            put("timestamp", System.currentTimeMillis())
            put("isMuted", false)
        }
        methodChannel?.invokeMethod("onCallState", payload.toString())
    }
}
