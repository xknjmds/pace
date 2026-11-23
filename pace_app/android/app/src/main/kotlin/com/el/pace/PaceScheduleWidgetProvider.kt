package com.el.pace

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import org.json.JSONObject

/**
 * Home-screen widget with today's classes (and calendar events), the
 * current one highlighted. Each widget has its own layout (list, time
 * blocks, now and next, day strip; see ScheduleWidgetConfigureActivity).
 *
 * Dart publishes the whole week (key "schedule_json", see
 * scheduleWidgetJson in lib/features/schedule/application/schedule_service.dart);
 * this works out "today" and "now" itself and sets an alarm for the next
 * block boundary or midnight, so it stays right without the app opening.
 * Reboots and clock changes re-arm it.
 */
class PaceScheduleWidgetProvider : HomeWidgetProvider() {
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
  ) = update(context, appWidgetManager, appWidgetIds, widgetData)

  /** Resized: the drawn layouts are redrawn at the new size. */
  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    update(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
  }

  override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    super.onDeleted(context, appWidgetIds)
    ScheduleWidgetPrefs.forget(context, appWidgetIds)
  }

  private fun refreshAll(context: Context) {
    val mgr = AppWidgetManager.getInstance(context)
    val ids = mgr.getAppWidgetIds(ComponentName(context, PaceScheduleWidgetProvider::class.java))
    if (ids.isNotEmpty()) update(context, mgr, ids, HomeWidgetPlugin.getData(context))
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

    /** Draws [ids] in their chosen layouts and arms the next refresh. */
    fun update(
        context: Context,
        mgr: AppWidgetManager,
        ids: IntArray,
        widgetData: SharedPreferences,
    ) {
      val now = System.currentTimeMillis()
      val json = widgetData.getString("schedule_json", null)
      val day = dayFrom(json, now)
      ids.forEach { id ->
        val views =
            when (ScheduleWidgetPrefs.layout(context, id)) {
              ScheduleWidgetLayout.LIST -> list(context, day)
              ScheduleWidgetLayout.NOW_NEXT -> nowNext(context, day)
              ScheduleWidgetLayout.TIMELINE -> timeline(context, day, mgr.getAppWidgetOptions(id))
              ScheduleWidgetLayout.STRIP -> strip(context, day, mgr.getAppWidgetOptions(id))
              ScheduleWidgetLayout.WEEK ->
                  week(context, day, weekFrom(json, now), mgr.getAppWidgetOptions(id))
            }
        views.setOnClickPendingIntent(
            R.id.schedule_root,
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("pace://schedule")))
        mgr.updateAppWidget(id, views)
      }
      scheduleNext(context, day.items, now)
    }

    /** No classes, or all done, in words; null when there is something to show. */
    private fun emptyText(context: Context, day: ScheduleDay, shown: List<ScheduleItem>): String? =
        when {
          day.noneToday -> context.getString(R.string.schedule_widget_none)
          shown.isEmpty() -> context.getString(R.string.schedule_widget_done)
          else -> null
        }

    private fun label(item: ScheduleItem) =
        if (item.room.isNullOrBlank()) item.title else "${item.title} · ${item.room}"

    private fun hm(t: Long) = ScheduleWidgetRenderer.hm(t)

    private fun list(context: Context, day: ScheduleDay): RemoteViews {
      val views = RemoteViews(context.packageName, R.layout.pace_schedule_widget)
      val shown = day.shown(ROWS)
      val empty = emptyText(context, day, shown)
      views.setViewVisibility(R.id.schedule_empty, if (empty == null) View.GONE else View.VISIBLE)
      views.setTextViewText(R.id.schedule_empty, empty ?: "")
      for (i in 0 until ROWS) {
        val row = ROW_IDS[i]
        val item = shown.getOrNull(i)
        if (item == null) {
          views.setViewVisibility(row.first, View.GONE)
          continue
        }
        views.setViewVisibility(row.first, View.VISIBLE)
        views.setInt(
            row.first,
            "setBackgroundResource",
            if (day.isNow(item)) R.drawable.pace_widget_row_now else android.R.color.transparent)
        views.setTextViewText(row.second, "${hm(item.start)}–${hm(item.end)}")
        views.setTextViewText(row.third, label(item))
      }
      return views
    }

    private fun nowNext(context: Context, day: ScheduleDay): RemoteViews {
      val views = RemoteViews(context.packageName, R.layout.pace_schedule_widget_now_next)
      val current = day.current
      val next = day.next
      val (headline, detail) =
          when {
            day.noneToday -> context.getString(R.string.schedule_widget_none) to null
            current != null ->
                current.title to
                    (if (current.room.isNullOrBlank())
                        context.getString(R.string.schedule_widget_until, hm(current.end))
                    else
                        context.getString(
                            R.string.schedule_widget_until_room, hm(current.end), current.room))
            next != null ->
                context.getString(R.string.schedule_widget_free) to
                    context.getString(R.string.schedule_widget_free_until, hm(next.start))
            else -> context.getString(R.string.schedule_widget_done) to null
          }
      views.setTextViewText(R.id.schedule_headline, headline)
      views.setViewVisibility(R.id.schedule_detail, if (detail == null) View.GONE else View.VISIBLE)
      views.setTextViewText(R.id.schedule_detail, detail ?: "")
      // Mint only while a block is under way; otherwise a quiet surface.
      views.setInt(
          R.id.schedule_now_box,
          "setBackgroundResource",
          if (current != null) R.drawable.pace_widget_row_now else android.R.color.transparent)
      val nextText =
          when {
            day.noneToday || (current == null && next != null) -> null
            next != null -> context.getString(R.string.schedule_widget_next, hm(next.start), label(next))
            current != null -> context.getString(R.string.schedule_widget_nothing_next)
            else -> null
          }
      views.setViewVisibility(R.id.schedule_next, if (nextText == null) View.GONE else View.VISIBLE)
      views.setTextViewText(R.id.schedule_next, nextText ?: "")
      return views
    }

    /** Widget size in dp: the width it gets, and the taller of its heights (portrait). */
    private fun sizeDp(options: Bundle): Pair<Int, Int> {
      val w = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
      val h = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 180)
      return w.coerceAtLeast(120) to h.coerceAtLeast(80)
    }

    private fun timeline(context: Context, day: ScheduleDay, options: Bundle): RemoteViews {
      val views = RemoteViews(context.packageName, R.layout.pace_schedule_widget_timeline)
      // Low energy: only now and next. Otherwise the whole day.
      val shown = if (day.lowEnergy) day.shown(2) else day.items
      val empty = emptyText(context, day, if (day.lowEnergy) shown else day.shown(ROWS))
      if (empty != null || shown.isEmpty()) {
        views.setViewVisibility(R.id.schedule_empty, View.VISIBLE)
        views.setTextViewText(R.id.schedule_empty, empty ?: context.getString(R.string.schedule_widget_done))
        views.setViewVisibility(R.id.schedule_canvas, View.GONE)
        return views
      }
      // Header (≈20dp), padding (24dp) and gap (6dp) leave the rest to the canvas.
      val (w, h) = sizeDp(options)
      val bmp = ScheduleWidgetRenderer(context).timeline(day, shown, w - 24, h - 56)
      views.setViewVisibility(R.id.schedule_empty, View.GONE)
      views.setViewVisibility(R.id.schedule_canvas, View.VISIBLE)
      views.setImageViewBitmap(R.id.schedule_canvas, bmp)
      views.setContentDescription(
          R.id.schedule_canvas,
          context.getString(
              R.string.schedule_widget_timeline_description,
              shown.joinToString(", ") { "${hm(it.start)} ${label(it)}" }))
      return views
    }

    private fun strip(context: Context, day: ScheduleDay, options: Bundle): RemoteViews {
      val views = RemoteViews(context.packageName, R.layout.pace_schedule_widget_strip)
      val current = day.current
      val next = day.next
      val (headline, detail) =
          when {
            day.noneToday -> context.getString(R.string.schedule_widget_none) to null
            current != null ->
                current.title to context.getString(R.string.schedule_widget_until, hm(current.end))
            next != null ->
                context.getString(R.string.schedule_widget_free) to
                    context.getString(R.string.schedule_widget_next, hm(next.start), label(next))
            else -> context.getString(R.string.schedule_widget_rest) to null
          }
      views.setTextViewText(R.id.schedule_headline, headline)
      views.setViewVisibility(R.id.schedule_detail, if (detail == null) View.GONE else View.VISIBLE)
      views.setTextViewText(R.id.schedule_detail, detail ?: "")
      val shown = if (day.lowEnergy) day.shown(2) else day.items
      if (shown.isEmpty()) {
        views.setViewVisibility(R.id.schedule_canvas, View.GONE)
        return views
      }
      val (w, _) = sizeDp(options)
      val bmp = ScheduleWidgetRenderer(context).strip(day, shown, w - 32, 44)
      views.setViewVisibility(R.id.schedule_canvas, View.VISIBLE)
      views.setImageViewBitmap(R.id.schedule_canvas, bmp)
      views.setContentDescription(
          R.id.schedule_canvas,
          context.getString(
              R.string.schedule_widget_timeline_description,
              shown.joinToString(", ") { "${hm(it.start)} ${label(it)}" }))
      return views
    }

    private fun week(
        context: Context,
        day: ScheduleDay,
        week: ScheduleWeek,
        options: Bundle,
    ): RemoteViews {
      // Low energy: the whole week is too much; show today's now and next.
      if (week.lowEnergy) return timeline(context, day, options)
      val views = RemoteViews(context.packageName, R.layout.pace_schedule_widget_week)
      views.setTextViewText(
          R.id.schedule_header_title, context.getString(R.string.schedule_widget_title_week))
      if (week.empty) {
        views.setViewVisibility(R.id.schedule_empty, View.VISIBLE)
        views.setTextViewText(R.id.schedule_empty, context.getString(R.string.schedule_widget_none_week))
        views.setViewVisibility(R.id.schedule_canvas, View.GONE)
        return views
      }
      val (w, h) = sizeDp(options)
      val bmp = ScheduleWidgetRenderer(context).week(week, w - 24, h - 56)
      views.setViewVisibility(R.id.schedule_empty, View.GONE)
      views.setViewVisibility(R.id.schedule_canvas, View.VISIBLE)
      views.setImageViewBitmap(R.id.schedule_canvas, bmp)
      views.setContentDescription(
          R.id.schedule_canvas,
          context.getString(
              R.string.schedule_widget_week_description,
              week.days
                  .filter { it.items.isNotEmpty() }
                  .joinToString("; ") { d ->
                    ScheduleWidgetRenderer.dayName(d.midnight) + ": " +
                        d.items.joinToString(", ") { "${hm(it.start)} ${label(it)}" }
                  }))
      return views
    }

    /** Today's blocks from the published week. */
    private fun dayFrom(json: String?, now: Long): ScheduleDay {
      if (json == null) return ScheduleDay(emptyList(), now, false)
      return try {
        val o = JSONObject(json)
        val midnight = startOfDay(now)
        ScheduleDay(itemsOn(o, midnight), now, o.optBoolean("lowEnergy", false))
      } catch (e: Exception) {
        ScheduleDay(emptyList(), now, false)
      }
    }

    /** Monday to Sunday of the week that holds [now]. */
    private fun weekFrom(json: String?, now: Long): ScheduleWeek {
      val today = startOfDay(now)
      val todayWeekday = weekdayOf(today)
      val monday = addDays(today, 1 - todayWeekday)
      val o =
          try {
            json?.let { JSONObject(it) }
          } catch (e: Exception) {
            null
          }
      val days =
          (0 until 7).map { i ->
            val midnight = addDays(monday, i)
            val items =
                try {
                  if (o == null) emptyList() else itemsOn(o, midnight)
                } catch (e: Exception) {
                  emptyList()
                }
            WeekDay(i + 1, midnight, items, midnight == today)
          }
      return ScheduleWeek(days, now, o?.optBoolean("lowEnergy", false) ?: false)
    }

    /** Calendar: Sunday = 1 ... Saturday = 7. PACE: Monday = 1 ... Sunday = 7. */
    private fun weekdayOf(t: Long): Int {
      val cal = Calendar.getInstance().apply { timeInMillis = t }
      return (cal.get(Calendar.DAY_OF_WEEK) + 5) % 7 + 1
    }

    /** [midnight] moved by [days] calendar days (safe across DST changes). */
    private fun addDays(midnight: Long, days: Int): Long =
        Calendar.getInstance()
            .apply {
              timeInMillis = midnight
              add(Calendar.DAY_OF_MONTH, days)
            }
            .timeInMillis

    /** Classes for the weekday of [midnight] plus events overlapping that day, sorted. */
    private fun itemsOn(o: JSONObject, midnight: Long): List<ScheduleItem> {
      val dayEnd = addDays(midnight, 1)
      val out = mutableListOf<ScheduleItem>()
      val classes = o.optJSONObject("classes")?.optJSONArray("${weekdayOf(midnight)}")
      if (classes != null) {
        for (i in 0 until classes.length()) {
          val c = classes.getJSONObject(i)
          out.add(
              ScheduleItem(
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
          if (s < dayEnd && f > midnight) out.add(ScheduleItem(s, f, e.getString("t"), null))
        }
      }
      return out.sortedBy { it.start }
    }

    /** Wakes at the next start or end today, or just after midnight. */
    private fun scheduleNext(context: Context, items: List<ScheduleItem>, now: Long) {
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
      // Exact alarms need no permission before Android 12 (API 31).
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()) {
        am.setExactAndAllowWhileIdle(AlarmManager.RTC, at, pi)
      } else {
        am.setWindow(AlarmManager.RTC, at, 60_000L, pi)
      }
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
  }
}
