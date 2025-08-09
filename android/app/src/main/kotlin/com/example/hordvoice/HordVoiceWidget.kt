package com.example.hordvoice

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HordVoiceWidget : HomeWidgetProvider() {
    
    companion object {
        private const val ACTION_TOGGLE_LISTENING = "com.example.hordvoice.TOGGLE_LISTENING"
        private const val ACTION_QUICK_COMMAND = "com.example.hordvoice.QUICK_COMMAND"
        private const val SHARED_PREFS = "HomeWidgetPreferences"
        
        fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, HordVoiceWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            val intent = Intent(context, HordVoiceWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        
        context?.let { ctx ->
            when (intent?.action) {
                ACTION_TOGGLE_LISTENING -> {
                    handleToggleListening(ctx)
                }
                ACTION_QUICK_COMMAND -> {
                    val command = intent.getStringExtra("command") ?: "weather"
                    handleQuickCommand(ctx, command)
                }
            }
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val widgetData = getWidgetData(context)
        val isListening = widgetData.getBoolean("is_listening", false)
        val statusText = widgetData.getString("status_text", "Touchez pour activer")
        val appName = widgetData.getString("app_name", "HordVoice")

        // Créer les vues du widget
        val views = RemoteViews(context.packageName, R.layout.hord_voice_widget)

        // Configurer le texte principal
        views.setTextViewText(R.id.widget_app_name, appName)
        views.setTextViewText(R.id.widget_status_text, statusText)

        // Configurer l'icône d'état
        val statusIcon = if (isListening) {
            R.drawable.ic_mic_on
        } else {
            R.drawable.ic_mic_off
        }
        views.setImageViewResource(R.id.widget_status_icon, statusIcon)

        // Configurer l'arrière-plan selon l'état
        val backgroundColor = if (isListening) {
            ContextCompat.getColor(context, R.color.widget_active_background)
        } else {
            ContextCompat.getColor(context, R.color.widget_inactive_background)
        }
        views.setInt(R.id.widget_container, "setBackgroundColor", backgroundColor)

        // Intent pour toggle listening
        val toggleIntent = Intent(context, HordVoiceWidget::class.java).apply {
            action = ACTION_TOGGLE_LISTENING
        }
        val togglePendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_toggle_button, togglePendingIntent)

        // Intent pour ouvrir l'app
        val openAppIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java
        )
        views.setOnClickPendingIntent(R.id.widget_app_name, openAppIntent)

        // Intents pour commandes rapides
        setupQuickCommandButton(context, views, R.id.widget_weather_button, "weather")
        setupQuickCommandButton(context, views, R.id.widget_news_button, "news")
        setupQuickCommandButton(context, views, R.id.widget_navigation_button, "navigation")

        // Mettre à jour le widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setupQuickCommandButton(
        context: Context,
        views: RemoteViews,
        buttonId: Int,
        command: String
    ) {
        val commandIntent = Intent(context, HordVoiceWidget::class.java).apply {
            action = ACTION_QUICK_COMMAND
            putExtra("command", command)
        }
        val commandPendingIntent = PendingIntent.getBroadcast(
            context,
            command.hashCode(),
            commandIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(buttonId, commandPendingIntent)
    }

    private fun handleToggleListening(context: Context) {
        // Notifier Flutter via background callback
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("hordvoice://toggle_listening")
        )
        context.sendBroadcast(backgroundIntent)
        
        // Mettre à jour le widget immédiatement pour feedback visuel
        updateWidget(context)
    }

    private fun handleQuickCommand(context: Context, command: String) {
        // Notifier Flutter via background callback
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("hordvoice://quick_command?cmd=$command")
        )
        context.sendBroadcast(backgroundIntent)
        
        // Optionnel: ouvrir l'app pour la commande
        val openAppIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java
        )
        openAppIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(openAppIntent)
    }

    private fun getWidgetData(context: Context): SharedPreferences {
        return context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
    }
}
