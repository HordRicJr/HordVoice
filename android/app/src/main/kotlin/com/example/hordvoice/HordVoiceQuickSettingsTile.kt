package com.example.hordvoice

import android.service.quicksettings.TileService
import android.service.quicksettings.Tile
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class HordVoiceQuickSettingsTile : TileService() {
    
    private val CHANNEL = "com.hordvoice/quick_settings"
    private var methodChannel: MethodChannel? = null
    
    override fun onCreate() {
        super.onCreate()
        initializeFlutterChannel()
    }
    
    private fun initializeFlutterChannel() {
        try {
            val flutterEngine = FlutterEngineCache.getInstance().get("my_engine_id")
            flutterEngine?.let { engine ->
                methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            }
        } catch (e: Exception) {
            // Flutter engine pas encore prêt
        }
    }
    
    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }
    
    override fun onClick() {
        super.onClick()
        
        // Réinitialiser channel si nécessaire
        if (methodChannel == null) {
            initializeFlutterChannel()
        }
        
        val currentState = qsTile.state
        val newState = if (currentState == Tile.STATE_ACTIVE) {
            Tile.STATE_INACTIVE
        } else {
            Tile.STATE_ACTIVE
        }
        
        // Notifier Flutter du changement d'état
        methodChannel?.invokeMethod("toggleListening", mapOf(
            "isActive" to (newState == Tile.STATE_ACTIVE),
            "source" to "quick_settings"
        ))
        
        // Mettre à jour le tile immédiatement
        updateTile(newState)
    }
    
    private fun updateTileState() {
        // Demander l'état actuel à Flutter
        methodChannel?.invokeMethod("getListeningState", null, object : MethodChannel.Result {
            override fun onSuccess(result: Any?) {
                val isListening = result as? Boolean ?: false
                val state = if (isListening) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
                updateTile(state)
            }
            
            override fun onError(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                updateTile(Tile.STATE_INACTIVE)
            }
            
            override fun onNotImplemented() {
                updateTile(Tile.STATE_INACTIVE)
            }
        })
    }
    
    private fun updateTile(state: Int) {
        qsTile?.let { tile ->
            tile.state = state
            
            when (state) {
                Tile.STATE_ACTIVE -> {
                    tile.label = "HordVoice ON"
                    tile.contentDescription = "Assistant vocal actif"
                    tile.icon = android.graphics.drawable.Icon.createWithResource(
                        this, 
                        android.R.drawable.ic_btn_speak_now
                    )
                }
                Tile.STATE_INACTIVE -> {
                    tile.label = "HordVoice OFF"
                    tile.contentDescription = "Assistant vocal inactif"
                    tile.icon = android.graphics.drawable.Icon.createWithResource(
                        this, 
                        android.R.drawable.ic_menu_close_clear_cancel
                    )
                }
                Tile.STATE_UNAVAILABLE -> {
                    tile.label = "HordVoice"
                    tile.contentDescription = "Assistant vocal non disponible"
                    tile.icon = android.graphics.drawable.Icon.createWithResource(
                        this, 
                        android.R.drawable.ic_dialog_info
                    )
                }
            }
            
            tile.updateTile()
        }
    }
}
