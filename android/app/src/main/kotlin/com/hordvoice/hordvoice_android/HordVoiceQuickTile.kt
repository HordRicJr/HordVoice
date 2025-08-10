package com.hordvoice.hordvoice_android

import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Service Quick Settings pour HordVoice
 * Permet d'activer/désactiver rapidement l'assistant vocal depuis les paramètres rapides
 */
class HordVoiceQuickTile : TileService() {
    
    companion object {
        private const val TAG = "HordVoiceQuickTile"
        private const val CHANNEL = "hordvoice/quick_tile"
    }
    
    private var isHordVoiceActive = false
    
    override fun onStartListening() {
        super.onStartListening()
        Log.d(TAG, "Quick Tile listening started")
        updateTileState()
    }
    
    override fun onStopListening() {
        super.onStopListening()
        Log.d(TAG, "Quick Tile listening stopped")
    }
    
    override fun onClick() {
        super.onClick()
        Log.d(TAG, "Quick Tile clicked")
        
        // Basculer l'état
        isHordVoiceActive = !isHordVoiceActive
        
        if (isHordVoiceActive) {
            // Démarrer HordVoice
            startHordVoice()
        } else {
            // Arrêter HordVoice
            stopHordVoice()
        }
        
        updateTileState()
    }
    
    /**
     * Met à jour l'état visuel du tile
     */
    private fun updateTileState() {
        val tile = qsTile ?: return
        
        if (isHordVoiceActive) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "HordVoice ON"
            tile.contentDescription = "HordVoice Assistant activé - Appuyez pour désactiver"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "HordVoice OFF"
            tile.contentDescription = "HordVoice Assistant désactivé - Appuyez pour activer"
        }
        
        tile.updateTile()
        Log.d(TAG, "Tile state updated: ${if (isHordVoiceActive) "ACTIVE" else "INACTIVE"}")
    }
    
    /**
     * Démarre HordVoice en lançant l'application
     */
    private fun startHordVoice() {
        try {
            Log.d(TAG, "Starting HordVoice...")
            
            // Créer un intent pour lancer l'application
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                intent.putExtra("quick_tile_action", "start_voice_assistant")
                startActivityAndCollapse(intent)
                Log.d(TAG, "HordVoice launched successfully")
            } else {
                Log.e(TAG, "Could not create launch intent for HordVoice")
                isHordVoiceActive = false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting HordVoice: ${e.message}")
            isHordVoiceActive = false
        }
    }
    
    /**
     * Arrête HordVoice
     */
    private fun stopHordVoice() {
        try {
            Log.d(TAG, "Stopping HordVoice...")
            
            // Pour arrêter, on peut envoyer un broadcast ou utiliser MethodChannel
            // si l'application est active
            val intent = Intent("com.hordvoice.STOP_VOICE_ASSISTANT")
            sendBroadcast(intent)
            
            Log.d(TAG, "HordVoice stop signal sent")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping HordVoice: ${e.message}")
        }
    }
    
    /**
     * Appelé quand le tile est ajouté aux paramètres rapides
     */
    override fun onTileAdded() {
        super.onTileAdded()
        Log.d(TAG, "HordVoice Quick Tile added to Quick Settings")
        updateTileState()
    }
    
    /**
     * Appelé quand le tile est supprimé des paramètres rapides
     */
    override fun onTileRemoved() {
        super.onTileRemoved()
        Log.d(TAG, "HordVoice Quick Tile removed from Quick Settings")
    }
}
