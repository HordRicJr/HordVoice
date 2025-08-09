package com.example.hordvoice

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hordvoice/quick_settings"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Mettre le FlutterEngine en cache pour le Quick Settings
        FlutterEngineCache
            .getInstance()
            .put("my_engine_id", flutterEngine)
        
        // Configurer le MethodChannel pour Quick Settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "test" -> {
                    result.success("pong from android")
                }
                "updateTileState" -> {
                    // Ici on pourrait notifier le TileService si nécessaire
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onDestroy() {
        // Nettoyer le cache si nécessaire
        FlutterEngineCache.getInstance().remove("my_engine_id")
        super.onDestroy()
    }
}
