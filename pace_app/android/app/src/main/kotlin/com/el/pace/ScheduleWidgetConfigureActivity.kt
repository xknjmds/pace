package com.el.pace

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Picks how one schedule widget looks: list, time blocks (today or the
 * week), now and next, or the day strip. Android opens it when the widget is placed (before
 * Android 12) or reconfigured (press and hold the widget). Native, so it
 * opens instantly without starting Flutter. Backing out keeps the widget
 * with its current (or the default list) layout.
 */
class ScheduleWidgetConfigureActivity : Activity() {
  private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    widgetId =
        intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
    if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
      finish()
      return
    }
    // Backing out still places the widget, with the list layout: placing a
    // widget should never fail because a choice was skipped.
    setResult(RESULT_OK, resultIntent())
    setContentView(R.layout.pace_widget_configure)

    val current = ScheduleWidgetPrefs.layout(this, widgetId)
    val options = findViewById<LinearLayout>(R.id.configure_options)
    val inflater = LayoutInflater.from(this)
    for ((layout, title, hint) in CHOICES) {
      val row = inflater.inflate(R.layout.pace_widget_configure_row, options, false)
      row.findViewById<TextView>(R.id.option_title).setText(title)
      row.findViewById<TextView>(R.id.option_hint).setText(hint)
      val chosen = layout == current
      row.isSelected = chosen
      row.findViewById<View>(R.id.option_check).visibility =
          if (chosen) View.VISIBLE else View.INVISIBLE
      row.contentDescription = "${getString(title)}. ${getString(hint)}"
      row.setOnClickListener { choose(layout) }
      options.addView(row)
    }
  }

  private fun choose(layout: ScheduleWidgetLayout) {
    ScheduleWidgetPrefs.setLayout(this, widgetId, layout)
    PaceScheduleWidgetProvider.update(
        this, AppWidgetManager.getInstance(this), intArrayOf(widgetId), HomeWidgetPlugin.getData(this))
    setResult(RESULT_OK, resultIntent())
    finish()
  }

  private fun resultIntent() = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)

  companion object {
    private val CHOICES =
        listOf(
            Triple(
                ScheduleWidgetLayout.LIST,
                R.string.schedule_widget_layout_list,
                R.string.schedule_widget_layout_list_hint),
            Triple(
                ScheduleWidgetLayout.TIMELINE,
                R.string.schedule_widget_layout_timeline,
                R.string.schedule_widget_layout_timeline_hint),
            Triple(
                ScheduleWidgetLayout.WEEK,
                R.string.schedule_widget_layout_week,
                R.string.schedule_widget_layout_week_hint),
            Triple(
                ScheduleWidgetLayout.NOW_NEXT,
                R.string.schedule_widget_layout_now_next,
                R.string.schedule_widget_layout_now_next_hint),
            Triple(
                ScheduleWidgetLayout.STRIP,
                R.string.schedule_widget_layout_strip,
                R.string.schedule_widget_layout_strip_hint),
        )
  }
}
