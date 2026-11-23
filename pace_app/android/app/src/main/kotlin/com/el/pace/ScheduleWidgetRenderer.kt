package com.el.pace

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils
import android.util.TypedValue
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min

/**
 * Draws the timeline, week and progress-strip layouts as bitmaps. RemoteViews
 * cannot size views by duration before Android 12, so these are drawn
 * on a Canvas at the widget's real size. Colours come from the widget
 * palette (values/ and values-night/pace_widget.xml); the block under way
 * is mint, never an alarm colour.
 */
class ScheduleWidgetRenderer(private val context: Context) {
  private val res = context.resources
  private val text = context.getColor(R.color.pace_widget_text)
  private val accent = context.getColor(R.color.pace_widget_accent)
  private val nowFill = context.getColor(R.color.pace_widget_now)

  private fun dp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, res.displayMetrics)

  private fun sp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, res.displayMetrics)

  private fun alpha(color: Int, a: Float) =
      Color.argb((Color.alpha(color) * a).toInt(), Color.red(color), Color.green(color), Color.blue(color))

  private fun paint(color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }

  private fun textPaint(color: Int, sizeSp: Float, bold: Boolean = false) =
      TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        this.color = color
        textSize = sp(sizeSp)
        typeface = if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        // Tabular figures so times line up.
        fontFeatureSettings = "tnum"
      }

  /** Widget size in pixels, capped so the bitmap stays inside the RemoteViews budget. */
  fun bitmap(widthDp: Int, heightDp: Int): Bitmap {
    val w = min(dp(widthDp.toFloat()).toInt(), MAX_PX).coerceAtLeast(1)
    val h = min(dp(heightDp.toFloat()).toInt(), MAX_PX).coerceAtLeast(1)
    return Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
  }

  /**
   * Blocks stacked along a time rail, each as tall as it is long, with a
   * line at the current time. Overlapping blocks (a class and a calendar
   * event) sit side by side.
   */
  fun timeline(day: ScheduleDay, items: List<ScheduleItem>, widthDp: Int, heightDp: Int): Bitmap {
    val bmp = bitmap(widthDp, heightDp)
    if (items.isEmpty()) return bmp
    val c = Canvas(bmp)
    val railW = dp(40f)
    val pad = dp(2f)
    val from = floorHour(items.minOf { it.start })
    val to = ceilHour(items.maxOf { it.end })
    val span = (to - from).coerceAtLeast(HOUR).toFloat()
    val top = dp(6f)
    val bottom = bmp.height - dp(6f)
    fun y(t: Long) = top + (bottom - top) * ((t - from) / span)

    // Hour labels and faint guides, skipped when they would crowd.
    val label = textPaint(alpha(text, .55f), 10f)
    val guide = paint(alpha(text, .08f)).apply { strokeWidth = dp(1f) }
    val hourPx = (bottom - top) * (HOUR / span)
    val every = if (hourPx >= sp(14f)) 1 else if (hourPx * 2 >= sp(14f)) 2 else 3
    var h = from
    var n = 0
    while (h <= to) {
      val yy = y(h)
      c.drawLine(railW, yy, bmp.width.toFloat(), yy, guide)
      if (n % every == 0) c.drawText(hm(h), 0f, min(yy + label.textSize / 3f, bottom), label)
      h += HOUR
      n++
    }

    val columns = overlapColumns(items)
    val twoCols = columns.any { it == 1 }
    val left = railW + dp(4f)
    val fullW = bmp.width - left
    val colW = if (twoCols) (fullW - pad) / 2f else fullW
    val radius = dp(10f)
    val titleP = textPaint(text, 13f, bold = true)
    val timeP = textPaint(alpha(text, .7f), 11f)

    items.forEachIndexed { i, it ->
      val past = it.end <= day.now
      val isNow = day.isNow(it)
      val x0 = left + columns[i] * (colW + pad)
      val r = RectF(x0, y(it.start) + pad, x0 + colW, y(it.end) - pad)
      if (r.height() < dp(4f)) r.bottom = r.top + dp(4f)
      val fill =
          when {
            isNow -> nowFill
            past -> alpha(text, .04f)
            else -> alpha(text, .08f)
          }
      c.drawRoundRect(r, radius, radius, paint(fill))
      val ink = if (past) .5f else 1f
      titleP.color = alpha(text, ink)
      timeP.color = alpha(text, .7f * ink)
      val inner = r.width() - dp(16f)
      if (inner <= 0f) return@forEachIndexed
      val lineH = titleP.textSize * 1.25f
      if (r.height() >= lineH + dp(6f)) {
        val title = if (it.room.isNullOrBlank()) it.title else "${it.title} · ${it.room}"
        val baseline = r.top + dp(4f) + titleP.textSize
        c.drawText(ellipsize(title, titleP, inner), r.left + dp(8f), baseline, titleP)
        if (r.height() >= lineH + timeP.textSize * 1.3f + dp(8f)) {
          c.drawText(
              "${hm(it.start)}–${hm(it.end)}",
              r.left + dp(8f),
              baseline + timeP.textSize * 1.35f,
              timeP)
        }
      }
    }

    // Now line across the day, with a dot on the rail.
    if (day.now in from..to) {
      val yy = y(day.now)
      val line = paint(accent).apply { strokeWidth = dp(2f) }
      c.drawLine(railW - dp(2f), yy, bmp.width.toFloat(), yy, line)
      c.drawCircle(railW - dp(2f), yy, dp(4f), paint(accent))
    }
    return bmp
  }

  /**
   * The week as columns, one per day, on a shared hour rail. Blocks are
   * as tall as they are long; today's column has a faint fill and the now
   * line. Earlier days read as done, never as missed.
   */
  fun week(week: ScheduleWeek, widthDp: Int, heightDp: Int): Bitmap {
    val bmp = bitmap(widthDp, heightDp)
    val all = week.items
    if (all.isEmpty() || week.days.isEmpty()) return bmp
    val c = Canvas(bmp)
    val railW = dp(36f)
    val pad = dp(1.5f)
    val headP = textPaint(alpha(text, .6f), 11f)
    val headToday = textPaint(accent, 11f, bold = true)
    val headH = headP.textSize + dp(6f)
    val top = headH + dp(4f)
    val bottom = bmp.height - dp(4f)

    // Shared span: earliest start to latest end by time of day.
    fun minuteOf(t: Long, midnight: Long) = (t - midnight) / MINUTE
    val fromMin =
        week.days.flatMap { d -> d.items.map { minuteOf(it.start, d.midnight).coerceAtLeast(0L) } }.min() / 60 * 60
    val toMinRaw =
        week.days.flatMap { d -> d.items.map { minuteOf(it.end, d.midnight).coerceAtMost(1440L) } }.max()
    val toMin = ((toMinRaw + 59) / 60 * 60).coerceAtLeast(fromMin + 60)
    val span = (toMin - fromMin).toFloat()
    fun y(minute: Long) = top + (bottom - top) * ((minute - fromMin) / span)

    // Hour labels and guides, thinned when they would crowd.
    val label = textPaint(alpha(text, .55f), 10f)
    val guide = paint(alpha(text, .08f)).apply { strokeWidth = dp(1f) }
    val hourPx = (bottom - top) * (60f / span)
    val every = if (hourPx >= sp(14f)) 1 else if (hourPx * 2 >= sp(14f)) 2 else 3
    var m = fromMin
    var n = 0
    while (m <= toMin) {
      val yy = y(m)
      c.drawLine(railW, yy, bmp.width.toFloat(), yy, guide)
      if (n % every == 0) {
        c.drawText("%02d:%02d".format(m / 60, m % 60), 0f, min(yy + label.textSize / 3f, bottom), label)
      }
      m += 60
      n++
    }

    val left = railW + dp(2f)
    val dayW = (bmp.width - left) / week.days.size
    val radius = dp(6f)
    val titleP = textPaint(text, 11f, bold = true)
    week.days.forEachIndexed { di, d ->
      val x0 = left + di * dayW
      if (d.isToday) {
        c.drawRoundRect(
            RectF(x0 + pad, 0f, x0 + dayW - pad, bottom), radius, radius, paint(alpha(accent, .08f)))
      }
      val name = dayName(d.midnight)
      val hp = if (d.isToday) headToday else headP
      val shown = ellipsize(name, hp, dayW - dp(4f))
      c.drawText(shown, x0 + (dayW - hp.measureText(shown)) / 2f, headP.textSize + dp(2f), hp)

      val columns = overlapColumns(d.items)
      val twoCols = columns.any { it == 1 }
      val colW = if (twoCols) (dayW - 3 * pad) / 2f else dayW - 2 * pad
      d.items.forEachIndexed { i, it ->
        val past = it.end <= week.now
        val isNow = week.now >= it.start && week.now < it.end
        val bx = x0 + pad + columns[i] * (colW + pad)
        val r =
            RectF(
                bx,
                y(minuteOf(it.start, d.midnight).coerceAtLeast(fromMin.toLong())) + pad,
                bx + colW,
                y(minuteOf(it.end, d.midnight).coerceAtMost(toMin.toLong())) - pad)
        if (r.height() < dp(3f)) r.bottom = r.top + dp(3f)
        val fill =
            when {
              isNow -> nowFill
              past -> alpha(text, .05f)
              else -> alpha(text, .10f)
            }
        c.drawRoundRect(r, radius, radius, paint(fill))
        val inner = r.width() - dp(6f)
        if (inner < dp(14f) || r.height() < titleP.textSize + dp(4f)) return@forEachIndexed
        titleP.color = alpha(text, if (past) .5f else 1f)
        c.drawText(
            ellipsize(it.title, titleP, inner), r.left + dp(3f), r.top + dp(2f) + titleP.textSize, titleP)
      }

      if (d.isToday) {
        val nowMin = minuteOf(week.now, d.midnight)
        if (nowMin in fromMin..toMin) {
          val yy = y(nowMin)
          val line = paint(accent).apply { strokeWidth = dp(2f) }
          c.drawLine(x0, yy, x0 + dayW, yy, line)
          c.drawCircle(x0 + dp(2f), yy, dp(3f), paint(accent))
        }
      }
    }
    return bmp
  }

  /** Side-by-side columns for overlaps (greedy, at most two). */
  private fun overlapColumns(items: List<ScheduleItem>): IntArray {
    val columns = IntArray(items.size)
    val lastEnd = longArrayOf(Long.MIN_VALUE, Long.MIN_VALUE)
    items.forEachIndexed { i, it ->
      val col = if (it.start >= lastEnd[0]) 0 else 1
      columns[i] = col
      lastEnd[col] = max(lastEnd[col], it.end)
    }
    return columns
  }

  /**
   * The day as one horizontal bar: blocks as segments, done ones filled,
   * the one under way in mint, a marker at now, and the day's first and
   * last times underneath.
   */
  fun strip(day: ScheduleDay, items: List<ScheduleItem>, widthDp: Int, heightDp: Int): Bitmap {
    val bmp = bitmap(widthDp, heightDp)
    if (items.isEmpty()) return bmp
    val c = Canvas(bmp)
    val from = items.minOf { it.start }
    val to = items.maxOf { it.end }
    val span = (to - from).coerceAtLeast(1L).toFloat()
    val barH = dp(14f)
    val top = dp(8f)
    val w = bmp.width.toFloat()
    fun x(t: Long) = w * ((t - from) / span)

    val track = RectF(0f, top, w, top + barH)
    c.drawRoundRect(track, barH / 2, barH / 2, paint(alpha(text, .06f)))
    val gap = dp(1.5f)
    items.forEach {
      val r = RectF(x(it.start) + gap, top, x(it.end) - gap, top + barH)
      if (r.width() < dp(2f)) r.right = r.left + dp(2f)
      val fill =
          when {
            day.isNow(it) -> nowFill
            it.end <= day.now -> alpha(accent, .35f)
            else -> alpha(text, .16f)
          }
      c.drawRoundRect(r, barH / 2, barH / 2, paint(fill))
    }
    if (day.now in from..to) {
      val xx = x(day.now).coerceIn(dp(1f), w - dp(1f))
      val marker = paint(accent).apply { strokeWidth = dp(2f) }
      c.drawLine(xx, top - dp(5f), xx, top + barH + dp(5f), marker)
    }
    val label = textPaint(alpha(text, .6f), 11f)
    val baseline = top + barH + dp(6f) + label.textSize
    if (baseline < bmp.height) {
      c.drawText(hm(from), 0f, baseline, label)
      val end = hm(to)
      c.drawText(end, w - label.measureText(end), baseline, label)
    }
    return bmp
  }

  private fun ellipsize(s: String, p: TextPaint, width: Float) =
      TextUtils.ellipsize(s, p, width, TextUtils.TruncateAt.END).toString()

  private fun floorHour(t: Long): Long =
      Calendar.getInstance()
          .apply {
            timeInMillis = t
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
          }
          .timeInMillis

  private fun ceilHour(t: Long): Long {
    val f = floorHour(t)
    return if (f == t) t else f + HOUR
  }

  companion object {
    private const val HOUR = 3_600_000L
    private const val MINUTE = 60_000L

    /** Keeps a full-size bitmap well inside the RemoteViews memory budget. */
    private const val MAX_PX = 1200

    /** Short weekday name in the phone's language, like "Mon". */
    fun dayName(t: Long): String =
        java.text.SimpleDateFormat("EEE", java.util.Locale.getDefault()).format(java.util.Date(t))

    fun hm(t: Long): String {
      val c = Calendar.getInstance().apply { timeInMillis = t }
      return "%02d:%02d".format(c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE))
    }
  }
}
