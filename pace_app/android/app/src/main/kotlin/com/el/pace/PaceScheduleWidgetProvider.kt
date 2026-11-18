package com.el.pace

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import org.json.JSONObject

/**
 * Home-screen widget with today's classes (and calendar events) as time
 * blocks, the current one highlighted. Dart publishes the whole week
 * (key "schedule_json", see scheduleWidgetJson in
 * lib/features/schedule/application/schedule_service.dart); this works out
 * "today" and "now" itself and sets an alarm for the next block boundary
 * or midnight, so it stays right without the app opening. Reboots and
 * clock changes re-arm it.
 */
class PaceScheduleWidgetProvider : HomeWidgetProvider() {
  private data class Item(val start: Long, val end: Long, val title: String, val room: String?)

  override fun onReceive(context: Context, intent: Intent) {
    when (intent.action) {
      Intent.ACTION_BOOT_COMPLETED,
      Intent.ACTION_TIME_CHANGED,
      Intent.ACTION_TIMEZONE_CHANGED,
      Intent.ACTION_DATE_CHANGED,
      Intent.ACTION_MY_PACKAGE_REPLACED,
      ACTION_TICK -> refreshAll(context)
      else -> super.onReceive(context, intent)
    }
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val now = System.currentTimeMillis()
    val data = widgetData.getString("schedule_json", null)
    val (items, lowEnergy) = itemsForToday(data, now)
    val current = items.indexOfFirst { now >= it.start && now < it.end }
    val shown =
        if (lowEnergy) {
          // Only what is under way and what comes next.
          val from = if (current >= 0) current else items.indexOfFirst { it.start > now }
          if (from < 0) emptyList() else items.drop(from).take(2)
        } else {
          // Keep the current block in view; show from one before it.
          val from = (if (current >= 0) current else items.indexOfFirst { it.end > now }).let {
            if (it < 0) (items.size - ROWS).coerceAtLeast(0) else (it - 1).coerceAtLeast(0)
          }
          items.drop(from).take(ROWS)
        }

    appWidgetIds.forEach { id ->
      val views = RemoteViews(context.packageName, R.layout.pace_schedule_widget)
      views.setOnClickPendingIntent(
          R.id.schedule_root,
          HomeWidgetLaunchIntent.getActivity(
              context, MainActivity::class.java, Uri.parse("pace://schedule")))
      val empty =
          when {
            items.isEmpty() -> context.getString(R.string.schedule_widget_none)
            shown.isEmpty() -> context.getString(R.string.schedule_widget_done)
            else -> null
          }
      views.setViewVisibility(R.id.schedule_empty, if (empty == null) View.GONE else View.VISIBLE)
      views.setTextViewText(R.id.schedule_empty, empty ?: "")
      for (i in 0 until ROWS) {
        val row = ROW_IDS[i]
        val item = shown.getOrNull(i)
        if (item == null) {
          views.setViewVisibility(row.first, View.GONE)
          continue
        }
        val isNow = now >= item.start && now < item.end
        views.setViewVisibility(row.first, View.VISIBLE)
        views.setInt(
            row.first,
            "setBackgroundResource",
            if (isNow) R.drawable.pace_widget_row_now else android.R.color.transparent)
        views.setTextViewText(row.second, "${hm(item.start)}–${hm(item.end)}")
        views.setTextViewText(
            row.third, if (item.room.isNullOrBlank()) item.title else "${item.title} · ${item.room}")
      }
      appWidgetManager.updateAppWidget(id, views)
    }
    scheduleNext(context, items, now)
  }

  private fun itemsForToday(json: String?, now: Long): Pair<List<Item>, Boolean> {
    if (json == null) return emptyList<Item>() to false
    return try {
      val o = JSONObject(json)
      val cal = Calendar.getInstance().apply { timeInMillis = now }
      // Calendar: Sunday = 1 ... Saturday = 7. PACE: Monday = 1 ... Sunday = 7.
      val weekday = (cal.get(Calendar.DAY_OF_WEEK) + 5) % 7 + 1
      val midnight = startOfDay(now)
      val dayEnd = startOfDay(midnight + 26 * 3_600_000L)
      val out = mutableListOf<Item>()
      val classes = o.optJSONObject("classes")?.optJSONArray("$weekday")
      if (classes != null) {
        for (i in 0 until classes.length()) {
          val c = classes.getJSONObject(i)
          out.add(
              Item(
                  atMinute(midnight, c.getInt("s")),
                  atMinute(midnight, c.getInt("e")),
                  c.getString("t"),
                  c.optString("r").ifBlank { null }))
        }
      }
      val events = o.optJSONArray("events")
      if (events != null) {
        for (i in 0 until events.length()) {
          val e = events.getJSONObject(i)
          val s = e.getLong("s")
          val f = e.getLong("e")
          if (s < dayEnd && f > midnight) out.add(Item(s, f, e.getString("t"), null))
        }
      }
      out.sortedBy { it.start } to o.optBoolean("lowEnergy", false)
    } catch (e: Exception) {
      emptyList<Item>() to false
    }
  }

  /** Wakes at the next start or end today, or just after midnight. */
  private fun scheduleNext(context: Context, items: List<Item>, now: Long) {
    val boundaries = items.flatMap { listOf(it.start, it.end) }.filter { it > now }
    val midnight = startOfDay(startOfDay(now) + 26 * 3_600_000L) + 60_000L
    val at = (boundaries.minOrNull() ?: midnight).coerceAtMost(midnight)
    val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val pi =
        PendingIntent.getBroadcast(
            context,
            REQUEST,
            Intent(context, PaceScheduleWidgetProvider::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    if (am.canScheduleExactAlarms()) {
      am.setExactAndAllowWhileIdle(AlarmManager.RTC, at, pi)
    } else {
      am.setWindow(AlarmManager.RTC, at, 60_000L, pi)
    }
  }

  private fun refreshAll(context: Context) {
    val mgr = AppWidgetManager.getInstance(context)
    val ids = mgr.getAppWidgetIds(ComponentName(context, PaceScheduleWidgetProvider::class.java))
    if (ids.isNotEmpty()) onUpdate(context, mgr, ids, HomeWidgetPlugin.getData(context))
  }

  private fun startOfDay(t: Long): Long =
      Calendar.getInstance()
          .apply {
            timeInMillis = t
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
          }
          .timeInMillis

  private fun atMinute(midnight: Long, minutes: Int): Long =
      Calendar.getInstance()
          .apply {
            timeInMillis = midnight
            set(Calendar.HOUR_OF_DAY, minutes / 60)
            set(Calendar.MINUTE, minutes % 60)
          }
          .timeInMillis

  private fun hm(t: Long): String {
    val c = Calendar.getInstance().apply { timeInMillis = t }
    return "%02d:%02d".format(c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE))
  }

  companion object {
    const val ACTION_TICK = "com.el.pace.SCHEDULE_WIDGET_TICK"
    private const val REQUEST = 4201
    private const val ROWS = 5
    private val ROW_IDS =
        listOf(
            Triple(R.id.schedule_row_0, R.id.schedule_time_0, R.id.schedule_title_0),
            Triple(R.id.schedule_row_1, R.id.schedule_time_1, R.id.schedule_title_1),
            Triple(R.id.schedule_row_2, R.id.schedule_time_2, R.id.schedule_title_2),
            Triple(R.id.schedule_row_3, R.id.schedule_time_3, R.id.schedule_title_3),
            Triple(R.id.schedule_row_4, R.id.schedule_time_4, R.id.schedule_title_4),
        )
  }
}
