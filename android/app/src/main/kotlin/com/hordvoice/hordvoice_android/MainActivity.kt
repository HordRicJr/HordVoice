package com.hordvoice.hordvoice_android

import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import com.microsoft.cognitiveservices.speech.SpeechConfig
import com.microsoft.cognitiveservices.speech.SpeechRecognizer
import com.microsoft.cognitiveservices.speech.PhraseListGrammar
import com.microsoft.cognitiveservices.speech.PropertyId
import com.microsoft.cognitiveservices.speech.ResultReason
import com.microsoft.cognitiveservices.speech.CancellationReason
import com.microsoft.cognitiveservices.speech.audio.AudioConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CompletableFuture

class MainActivity : FlutterActivity() {
    private val SPEECH_CHANNEL = "azure_speech_custom"
    private var speechConfig: SpeechConfig? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var phraseListGrammar: PhraseListGrammar? = null
    
    // Azure Speech Service credentials - Vraies clés HordVoice
    private val SPEECH_SUBSCRIPTION_KEY = "BWkbBCvtCTaZB6ijvlJsYgFgSCSLxo3ARJp8835NL3fE24vrDcRIJQQJ99BHACYeBjFXJ3w3AAAYACOGFcSl"
    private val SPEECH_REGION = "eastus"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("MainActivity", "Configuration du Platform Channel Azure Speech")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configurePhraseHints" -> {
                    configurePhraseHints(call, result)
                }
                "clearPhraseHints" -> {
                    clearPhraseHints(result)
                }
                "initializeSpeechRecognizer" -> {
                    initializeSpeechRecognizer(result)
                }
                "startContinuousRecognition" -> {
                    startContinuousRecognition(result)
                }
                "stopContinuousRecognition" -> {
                    stopContinuousRecognition(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Initialiser Azure Speech Config au démarrage
        initializeAzureSpeechConfig()
    }
    
    /**
     * Initialise la configuration Azure Speech
     */
    private fun initializeAzureSpeechConfig() {
        try {
            Log.d("MainActivity", "Initialisation Azure Speech Config")
            
            speechConfig = SpeechConfig.fromSubscription(SPEECH_SUBSCRIPTION_KEY, SPEECH_REGION)
            speechConfig?.let { config ->
                // Configuration pour le français
                config.speechRecognitionLanguage = "fr-FR"
                
                // Optimisations pour la reconnaissance vocale
                config.setProperty(PropertyId.SpeechServiceConnection_InitialSilenceTimeoutMs, "5000")
                config.setProperty(PropertyId.SpeechServiceConnection_EndSilenceTimeoutMs, "2000")
                config.setProperty(PropertyId.Speech_SegmentationSilenceTimeoutMs, "500")
                
                // Mode de reconnaissance continue
                config.setProperty(PropertyId.SpeechServiceConnection_RecoMode, "INTERACTIVE")
                
                Log.d("MainActivity", "Azure Speech Config initialisée avec succès")
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur lors de l'initialisation Azure Speech Config: ${e.message}")
        }
    }
    
    /**
     * Configure les Phrase Hints reçues de Flutter
     */
    private fun configurePhraseHints(call: MethodCall, result: MethodChannel.Result) {
        try {
            val phrases: List<String>? = call.argument("phrases")
            val context: String? = call.argument("context")
            
            if (phrases == null || phrases.isEmpty()) {
                Log.w("MainActivity", "Aucune phrase reçue pour la configuration")
                result.success(false)
                return
            }
            
            Log.d("MainActivity", "Configuration de ${phrases.size} phrases pour le contexte: $context")
            
            // S'assurer que speechConfig est initialisé
            if (speechConfig == null) {
                initializeAzureSpeechConfig()
            }
            
            speechConfig?.let { config ->
                try {
                    Log.d("MainActivity", "Début configuration phrase hints avec SpeechConfig valide")
                    
                    // Créer un recognizer temporaire pour configurer les phrase hints
                    val audioConfig = AudioConfig.fromDefaultMicrophoneInput()
                    val tempRecognizer = SpeechRecognizer(config, audioConfig)
                    
                    // Vérifier que le recognizer est valide avant de continuer
                    if (tempRecognizer == null) {
                        Log.e("MainActivity", "Erreur: SpeechRecognizer temporaire est null")
                        result.success(false)
                        return@let
                    }
                    
                    // Créer le PhraseListGrammar
                    phraseListGrammar = PhraseListGrammar.fromRecognizer(tempRecognizer)
                    
                    if (phraseListGrammar == null) {
                        Log.e("MainActivity", "Erreur: PhraseListGrammar est null")
                        tempRecognizer.close()
                        result.success(false)
                        return@let
                    }
                    
                    // Ajouter chaque phrase au grammar
                    phrases.forEach { phrase ->
                        try {
                            phraseListGrammar?.addPhrase(phrase)
                            Log.v("MainActivity", "Phrase ajoutée: $phrase")
                        } catch (e: Exception) {
                            Log.w("MainActivity", "Impossible d'ajouter la phrase '$phrase': ${e.message}")
                        }
                    }
                    
                    Log.i("MainActivity", "✅ ${phrases.size} phrases configurées avec succès dans Azure Speech SDK")
                    
                    // Nettoyer le recognizer temporaire
                    tempRecognizer.close()
                    
                    result.success(true)
                    
                } catch (e: Exception) {
                    Log.e("MainActivity", "Erreur lors de la configuration des phrases: ${e.message}")
                    Log.e("MainActivity", "Stack trace: ${e.stackTraceToString()}")
                    result.success(false)
                }
            } ?: run {
                Log.e("MainActivity", "SpeechConfig non initialisé")
                result.success(false)
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur dans configurePhraseHints: ${e.message}")
            result.success(false)
        }
    }
    
    /**
     * Efface toutes les phrases configurées
     */
    private fun clearPhraseHints(result: MethodChannel.Result) {
        try {
            Log.d("MainActivity", "Effacement des phrase hints")
            
            phraseListGrammar?.clear()
            phraseListGrammar = null
            
            Log.i("MainActivity", "Phrase hints effacées avec succès")
            result.success(true)
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur lors de l'effacement des phrase hints: ${e.message}")
            result.success(false)
        }
    }
    
    /**
     * Initialise le Speech Recognizer avec phrase hints
     */
    private fun initializeSpeechRecognizer(result: MethodChannel.Result) {
        try {
            Log.d("MainActivity", "Initialisation du Speech Recognizer")
            
            speechConfig?.let { config ->
                val audioConfig = AudioConfig.fromDefaultMicrophoneInput()
                speechRecognizer = SpeechRecognizer(config, audioConfig)
                
                // Recréer phrase hints si elles existent
                phraseListGrammar?.let {
                    phraseListGrammar = PhraseListGrammar.fromRecognizer(speechRecognizer!!)
                    Log.d("MainActivity", "Phrase hints réappliquées au nouveau recognizer")
                }
                
                Log.i("MainActivity", "Speech Recognizer initialisé avec succès")
                result.success(true)
                
            } ?: run {
                Log.e("MainActivity", "SpeechConfig non disponible")
                result.success(false)
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur lors de l'initialisation du recognizer: ${e.message}")
            result.success(false)
        }
    }
    
    /**
     * Démarre la reconnaissance continue
     */
    private fun startContinuousRecognition(result: MethodChannel.Result) {
        try {
            Log.d("MainActivity", "Démarrage de la reconnaissance continue")
            
            speechRecognizer?.let { recognizer ->
                
                // Configuration des événements de reconnaissance
                recognizer.recognizing.addEventListener { _, e ->
                    Log.v("MainActivity", "Reconnaissance en cours: ${e.result.text}")
                }
                
                recognizer.recognized.addEventListener { _, e ->
                    when (e.result.reason) {
                        ResultReason.RecognizedSpeech -> {
                            Log.i("MainActivity", "✅ Texte reconnu: ${e.result.text}")
                            // Ici on pourrait renvoyer le résultat à Flutter via MethodChannel
                        }
                        ResultReason.NoMatch -> {
                            Log.w("MainActivity", "Aucune correspondance trouvée")
                        }
                        else -> {
                            Log.w("MainActivity", "Résultat de reconnaissance: ${e.result.reason}")
                        }
                    }
                }
                
                recognizer.canceled.addEventListener { _, e ->
                    Log.e("MainActivity", "Reconnaissance annulée: ${e.reason}")
                    if (e.reason == CancellationReason.Error) {
                        Log.e("MainActivity", "Erreur: ${e.errorDetails}")
                    }
                }
                
                // Démarrer la reconnaissance continue
                val startTask = recognizer.startContinuousRecognitionAsync()
                startTask.get() // Attendre que la tâche soit terminée
                
                Log.i("MainActivity", "Reconnaissance continue démarrée avec succès")
                result.success(true)
                
            } ?: run {
                Log.e("MainActivity", "Speech Recognizer non initialisé")
                result.success(false)
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur lors du démarrage de la reconnaissance: ${e.message}")
            result.success(false)
        }
    }
    
    /**
     * Arrête la reconnaissance continue
     */
    private fun stopContinuousRecognition(result: MethodChannel.Result) {
        try {
            Log.d("MainActivity", "Arrêt de la reconnaissance continue")
            
            speechRecognizer?.let { recognizer ->
                val stopTask = recognizer.stopContinuousRecognitionAsync()
                stopTask.get() // Attendre que la tâche soit terminée
                
                Log.i("MainActivity", "Reconnaissance continue arrêtée avec succès")
                result.success(true)
                
            } ?: run {
                Log.w("MainActivity", "Speech Recognizer non initialisé - rien à arrêter")
                result.success(true)
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur lors de l'arrêt de la reconnaissance: ${e.message}")
            result.success(false)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        try {
            // Nettoyer les ressources Azure Speech
            speechRecognizer?.close()
            speechConfig?.close()
            phraseListGrammar?.close()
            
            Log.d("MainActivity", "Ressources Azure Speech nettoyées")
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur lors du nettoyage: ${e.message}")
        }
    }
}
