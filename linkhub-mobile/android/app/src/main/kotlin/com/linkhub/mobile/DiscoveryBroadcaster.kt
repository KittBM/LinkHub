package com.linkhub.mobile

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

object DiscoveryBroadcaster {
    private var job: Job? = null

    fun start(deviceId: String, deviceName: String, port: Int = 8765) {
        job?.cancel()
        job = CoroutineScope(Dispatchers.IO).launch {
            val payload = JSONObject().apply {
                put("type", "linkhub_mobile")
                put("id", deviceId)
                put("name", deviceName)
                put("port", port)
            }.toString().toByteArray()

            val socket = DatagramSocket()
            socket.broadcast = true

            while (isActive) {
                try {
                    val packet = DatagramPacket(
                        payload,
                        payload.size,
                        InetAddress.getByName("255.255.255.255"),
                        8766
                    )
                    socket.send(packet)
                } catch (_: Exception) {}
                delay(3000)
            }
            socket.close()
        }
    }

    fun stop() {
        job?.cancel()
        job = null
    }
}
