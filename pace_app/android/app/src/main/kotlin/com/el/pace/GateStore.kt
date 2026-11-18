package com.el.pace

import android.content.Context
import org.json.JSONArray

/**
 * The app gate's configuration, written by Dart (lib/features/blocking)
 * through MainActivity and read by GateService and BlockActivity. Lock
 * windows are absolute instants; the routine logic stays in Dart.
 */
class GateStore(context: Context) {
  private val prefs = context.getSharedPreferences("pace_gate", Context.MODE_PRIVATE)

  data class Window(val start: Long, val end: Long, val reason: String)

  var enabled: Boolean
    get() = prefs.getBoolean("enabled", false)
    set(v) = prefs.edit().putBoolean("enabled", v).apply()

  var packages: Set<String>
    get() = prefs.getStringSet("packages", emptySet()) ?: emptySet()
    set(v) = prefs.edit().putStringSet("packages", v).apply()

  var unlockMinutes: Int
    get() = prefs.getInt("unlock_minutes", 10)
    set(v) = prefs.edit().putInt("unlock_minutes", v).apply()

  var unlockedUntil: Long
    get() = prefs.getLong("unlocked_until", 0)
    set(v) = prefs.edit().putLong("unlocked_until", v).apply()

  var windows: List<Window>
    get() {
      val raw = prefs.getString("windows", "[]") ?: "[]"
      val arr = JSONArray(raw)
      return (0 until arr.length()).map {
        val o = arr.getJSONObject(it)
        Window(o.getLong("start"), o.getLong("end"), o.optString("reason", "morning"))
      }
    }
    set(v) {
      val arr = JSONArray()
      v.forEach {
        arr.put(
            org.json.JSONObject()
                .put("start", it.start)
                .put("end", it.end)
                .put("reason", it.reason))
      }
      prefs.edit().putString("windows", arr.toString()).apply()
    }

  fun activeWindow(now: Long): Window? = windows.firstOrNull { now >= it.start && now < it.end }

  fun nextStart(now: Long): Long? = windows.map { it.start }.filter { it > now }.minOrNull()

  /** True when [pkg] should be held back right now. */
  fun blocks(pkg: String, now: Long): Boolean =
      enabled && now >= unlockedUntil && activeWindow(now) != null && pkg in packages

  /** Emergency unlock: always allowed, never hidden. */
  fun unlockFor(minutes: Int, now: Long = System.currentTimeMillis()) {
    unlockedUntil = now + minutes * 60_000L
  }
}
