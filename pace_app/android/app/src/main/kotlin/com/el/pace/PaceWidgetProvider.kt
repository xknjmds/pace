package com.el.pace

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: the inbox count and one button to write a thought
 * down. Values come from Dart through home_widget (key "inbox_count").
 * Kept in step with HomeWidgetKeys in lib/core/home_widget.
 */
class PaceWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val count = widgetData.getInt("inbox_count", 0)
    val countText =
        when (count) {
          0 -> context.getString(R.string.widget_inbox_clear)
          1 -> context.getString(R.string.widget_inbox_one)
          else -> context.getString(R.string.widget_inbox_many, count)
        }
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.pace_widget).apply {
            setTextViewText(R.id.widget_count, countText)
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("pace://today")),
            )
            setOnClickPendingIntent(
                R.id.widget_capture,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("pace://capture")),
            )
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
