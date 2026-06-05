package com.linkhub.mobile

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.provider.Telephony
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val channel = "com.linkhub/agent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mc = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)

        // Pass channel to native services
        AgentNotificationListener.methodChannel = mc
        AgentTelecomReceiver.methodChannel = mc

        mc.setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startForegroundService(Intent(this, AgentForegroundService::class.java))
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopService(Intent(this, AgentForegroundService::class.java))
                    result.success(null)
                }
                "openNotificationListenerSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "notificationAction" -> {
                    AgentNotificationListener.performAction(
                        call.argument("id") ?: "",
                        call.argument("action") ?: "",
                        call.argument("text")
                    )
                    result.success(null)
                }
                "callAction" -> {
                    AgentTelecomReceiver.performCallAction(this, call.argument("action") ?: "")
                    result.success(null)
                }
                "sendSms" -> {
                    SmsSender.send(this, call.argument("to") ?: "", call.argument("body") ?: "")
                    result.success(null)
                }
                "getDeviceStatus" -> {
                    result.success(getDeviceStatus())
                }
                "getSmsList" -> {
                    val limit = call.argument<Int>("limit") ?: 100
                    result.success(getSmsList(limit))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat?.contains(packageName) == true
    }

    private fun getDeviceStatus(): Map<String, Any> {
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = bm.isCharging

        val wifiMgr = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiInfo = wifiMgr.connectionInfo
        val wifiConnected = wifiInfo.networkId != -1
        val wifiName = wifiInfo.ssid?.replace("\"", "") ?: ""

        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val signalStrength = 0 // Requires PhoneStateListener for real value

        val stat = StatFs(Environment.getDataDirectory().path)
        val storageTotal = stat.totalBytes
        val storageUsed = storageTotal - stat.availableBytes

        val ip = wifiMgr.connectionInfo.ipAddress
        val ipStr = "${ip and 0xFF}.${ip shr 8 and 0xFF}.${ip shr 16 and 0xFF}.${ip shr 24 and 0xFF}"

        return mapOf(
            "id" to "",
            "name" to android.os.Build.MODEL,
            "batteryLevel" to batteryLevel,
            "isCharging" to isCharging,
            "wifiConnected" to wifiConnected,
            "wifiName" to wifiName,
            "signalStrength" to signalStrength,
            "storageUsed" to storageUsed,
            "storageTotal" to storageTotal,
            "ipAddress" to ipStr,
            "isConnected" to true,
            "lastSeen" to System.currentTimeMillis()
        )
    }

    private fun getSmsList(limit: Int): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val uri = Telephony.Sms.CONTENT_URI
        val cursor: Cursor? = contentResolver.query(
            uri,
            arrayOf("_id", "address", "body", "date", "type", "read"),
            null, null,
            "date DESC LIMIT $limit"
        )
        cursor?.use {
            val idIdx = it.getColumnIndexOrThrow("_id")
            val addrIdx = it.getColumnIndexOrThrow("address")
            val bodyIdx = it.getColumnIndexOrThrow("body")
            val dateIdx = it.getColumnIndexOrThrow("date")
            val typeIdx = it.getColumnIndexOrThrow("type")
            val readIdx = it.getColumnIndexOrThrow("read")

            while (it.moveToNext()) {
                messages.add(mapOf(
                    "id" to it.getString(idIdx),
                    "deviceId" to "",
                    "address" to (it.getString(addrIdx) ?: ""),
                    "contactName" to "",
                    "body" to (it.getString(bodyIdx) ?: ""),
                    "isIncoming" to (it.getInt(typeIdx) == Telephony.Sms.MESSAGE_TYPE_INBOX),
                    "isRead" to (it.getInt(readIdx) == 1),
                    "timestamp" to it.getLong(dateIdx)
                ))
            }
        }
        return messages
    }
}
