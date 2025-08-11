package com.hordvoice.hordvoice

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "hordvoice_spatial_channel",
                "HordVoice IA Spatiale",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Service d'IA spatiale persistante pour HordVoice"
            channel.setShowBadge(false)
            channel.enableLights(false)
            channel.enableVibration(false)
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
