package com.el.pace

import android.content.Context

/** How one schedule widget draws today. Chosen per widget when it is placed. */
enum class ScheduleWidgetLayout(val key: String) {
  LIST("list"),
  TIMELINE("timeline"),
  NOW_NEXT("now_next"),
  STRIP("strip");

  companion object {
    fun fromKey(key: String?): ScheduleWidgetLayout = entries.firstOrNull { it.key == key } ?: LIST
  }
}

/** Per-widget layout choice, keyed by app widget id. */
object ScheduleWidgetPrefs {
  private const val FILE = "pace_widget_layouts"

  private fun prefs(context: Context) = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

  fun layout(context: Context, id: Int): ScheduleWidgetLayout =
      ScheduleWidgetLayout.fromKey(prefs(context).getString("layout_$id", null))

  fun setLayout(context: Context, id: Int, layout: ScheduleWidgetLayout) {
    prefs(context).edit().putString("layout_$id", layout.key).apply()
  }

  fun forget(context: Context, ids: IntArray) {
    val edit = prefs(context).edit()
    ids.forEach { edit.remove("layout_$it") }
    edit.apply()
  }
}

/** One class or event today, as instants (ms). */
data class ScheduleItem(val start: Long, val end: Long, val title: String, val room: String?)

/**
 * What every layout needs to know about today at [now]. Pure: no Android
 * types, so the choice of "now" and "next" is the same in every layout.
 */
class ScheduleDay(val items: List<ScheduleItem>, val now: Long, val lowEnergy: Boolean) {
  /** The block under way, if any. */
  val current: ScheduleItem? = items.firstOrNull { now >= it.start && now < it.end }

  /** The next block to start. */
  val next: ScheduleItem? = items.firstOrNull { it.start > now }

  /** Nothing scheduled today at all. */
  val noneToday: Boolean get() = items.isEmpty()

  /** Everything today has finished. */
  val allDone: Boolean get() = items.isNotEmpty() && current == null && next == null

  /**
   * The blocks a layout shows. Low energy keeps only what is under way and
   * what comes next. Otherwise up to [max] rows, keeping the current block
   * in view with one before it.
   */
  fun shown(max: Int): List<ScheduleItem> {
    val currentIndex = items.indexOfFirst { now >= it.start && now < it.end }
    if (lowEnergy) {
      val from = if (currentIndex >= 0) currentIndex else items.indexOfFirst { it.start > now }
      return if (from < 0) emptyList() else items.drop(from).take(2)
    }
    val anchor = if (currentIndex >= 0) currentIndex else items.indexOfFirst { it.end > now }
    val from =
        if (anchor < 0) (items.size - max).coerceAtLeast(0) else (anchor - 1).coerceAtLeast(0)
    return items.drop(from).take(max)
  }

  /** Whether [item] is under way. */
  fun isNow(item: ScheduleItem): Boolean = now >= item.start && now < item.end
}
