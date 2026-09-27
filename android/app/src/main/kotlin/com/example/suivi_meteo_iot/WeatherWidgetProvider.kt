package com.example.meteo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Widget d'écran d'accueil : météo actuelle de la ville par défaut.
/// Les données sont écrites côté Dart (home_screen_widget.dart).
class WeatherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.weather_widget).apply {
                setTextViewText(R.id.widget_city, widgetData.getString("city", "Météo"))
                setTextViewText(R.id.widget_temperature, widgetData.getString("temperature", "--°"))
                setTextViewText(R.id.widget_emoji, widgetData.getString("emoji", "⛅"))
                val condition = widgetData.getString("condition", null)
                val updatedAt = widgetData.getString("updated_at", null)
                setTextViewText(
                    R.id.widget_condition,
                    if (condition == null) "Ouvrez l'app pour charger la météo"
                    else "$condition · $updatedAt",
                )
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
