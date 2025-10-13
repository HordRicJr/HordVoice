package com.hordvoice.hordvoice

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val AZURE_SPEECH_CHANNEL = "azure_speech_recognition"
    private val AZURE_SPEECH_CUSTOM_CHANNEL = "azure_speech_custom"
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configuration du canal Azure Speech Recognition
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AZURE_SPEECH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecognition" -> {
                    // TODO: Implémenter la reconnaissance Azure Speech
                    result.success("Azure Speech Recognition non encore implémenté")
                }
                else -> result.notImplemented()
            }
        }
        
        // Configuration du canal Azure Speech Custom (Phrase Hints)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AZURE_SPEECH_CUSTOM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configurePhraseHints" -> {
                    // TODO: Implémenter la configuration des phrase hints
                    result.success("Phrase hints configuration non encore implémentée")
                }
                else -> result.notImplemented()
            }
        }
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
