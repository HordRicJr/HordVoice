package com.hordvoice.hordvoice_app

import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * HordVoice Quick Settings Tile
 * Permet d'activer/désactiver l'assistant vocal directement depuis les paramètres rapides
 */
class HordVoiceQuickTile : TileService() {
    
    companion object {
        private const val TAG = "HordVoiceQuickTile"
        private const val CHANNEL_NAME = "com.hordvoice/quick_settings"
        private const val ENGINE_ID = "hordvoice_background_engine"
    }
    
    private var isListening = false
    private var methodChannel: MethodChannel? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "HordVoice Quick Tile créé")
        setupFlutterEngine()
    }
    
    private fun setupFlutterEngine() {
        try {
            val engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
            if (engine != null) {
                methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
                Log.d(TAG, "Method channel configuré")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erreur configuration Flutter Engine: ${e.message}")
        }
    }
    
    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
        Log.d(TAG, "Quick Tile listening started")
    }
    
    override fun onClick() {
        super.onClick()
        
        // Toggle l'état d'écoute
        isListening = !isListening
        
        try {
            // Notifier Flutter du changement d'état
            methodChannel?.invokeMethod("toggleListening", mapOf(
                "isActive" to isListening,
                "source" to "quick_tile"
            ))
            
            // Démarrer l'activité principale si pas déjà ouverte
            if (isListening) {
                startHordVoiceActivity()
            }
            
            updateTileState()
            
            Log.d(TAG, "Quick Tile clicked: listening = $isListening")
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur onClick: ${e.message}")
            // Revenir à l'état précédent en cas d'erreur
            isListening = !isListening
            updateTileState()
        }
    }
    
    private fun updateTileState() {
        val tile = qsTile ?: return
        
        try {
            if (isListening) {
                // État actif : avatar qui écoute
                tile.state = Tile.STATE_ACTIVE
                tile.label = "HordVoice Actif"
                tile.subtitle = "Je vous écoute..."
                tile.icon = Icon.createWithResource(this, android.R.drawable.ic_media_play)
            } else {
                // État inactif : avatar en veille
                tile.state = Tile.STATE_INACTIVE
                tile.label = "HordVoice"
                tile.subtitle = "Toucher pour activer"
                tile.icon = Icon.createWithResource(this, android.R.drawable.ic_media_pause)
            }
            
            tile.updateTile()
            Log.d(TAG, "Tile state updated: $isListening")
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur update tile state: ${e.message}")
        }
    }
    
    private fun startHordVoiceActivity() {
        try {
            val intent = Intent(this, io.flutter.embedding.android.FlutterActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("from_quick_tile", true)
                putExtra("auto_start_listening", true)
            }
            startActivity(intent)
            Log.d(TAG, "HordVoice activity started from Quick Tile")
        } catch (e: Exception) {
            Log.e(TAG, "Erreur start activity: ${e.message}")
        }
    }
    
    override fun onTileRemoved() {
        super.onTileRemoved()
        Log.d(TAG, "HordVoice Quick Tile removed")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        methodChannel = null
        Log.d(TAG, "HordVoice Quick Tile destroyed")
    }
}
