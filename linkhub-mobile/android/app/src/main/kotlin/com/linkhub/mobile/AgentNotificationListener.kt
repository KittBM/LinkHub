package com.linkhub.mobile

import android.app.Notification
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class AgentNotificationListener : NotificationListenerService() {
    companion object {
        private val activeNotifs = mutableMapOf<String, StatusBarNotification>()
        var methodChannel: MethodChannel? = null

        fun performAction(key: String, action: String, replyText: String?) {
            val sbn = activeNotifs[key] ?: return
            when (action) {
                "dismiss" -> {
                    // cancelNotification is called on the service instance, not companion
                }
                "reply" -> {
                    val notification = sbn.notification
                    val actions = notification.actions ?: return
                    for (a in actions) {
                        val remoteInputs = a.remoteInputs ?: continue
                        if (remoteInputs.isNotEmpty() && replyText != null) {
                            val intent = a.actionIntent
                            val bundle = Bundle()
                            for (ri in remoteInputs) {
                                bundle.putCharSequence(ri.resultKey, replyText)
                            }
                            val fillInIntent = android.content.Intent()
                            android.app.RemoteInput.addResultsToIntent(remoteInputs, fillInIntent, bundle)
                            try {
                                intent.send(null, 0, fillInIntent, null, null)
                            } catch (_: Exception) {}
                            return
                        }
                    }
                }
                "markRead" -> {
                    // Trigger the content intent to mark as read
                    try {
                        sbn.notification.contentIntent?.send()
                    } catch (_: Exception) {}
                }
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val appName = try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(sbn.packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            sbn.packageName
        }

        val hasReplyAction = sbn.notification.actions?.any { action ->
            action.remoteInputs?.isNotEmpty() == true
        } == true

        val actions = sbn.notification.actions?.map { it.title?.toString() ?: "" } ?: emptyList()

        val key = "${sbn.packageName}:${sbn.id}"
        activeNotifs[key] = sbn

        val payload = JSONObject().apply {
            put("id", key)
            put("appName", appName)
            put("packageName", sbn.packageName)
            put("title", title)
            put("message", text)
            put("timestamp", sbn.postTime)
            put("isRead", false)
            put("canReply", hasReplyAction)
            put("actions", actions)
        }

        methodChannel?.invokeMethod("onNotification", payload.toString())
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        val key = "${sbn.packageName}:${sbn.id}"
        activeNotifs.remove(key)
        methodChannel?.invokeMethod("onNotificationRemoved", key)
    }
}
