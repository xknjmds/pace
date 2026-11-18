package com.el.pace

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import java.text.DateFormat
import java.util.Date

/**
 * Keeps an eye on which app is in front during lock windows and shows
 * BlockActivity over a blocked one. Between windows it only sleeps until
 * the next one starts, so it costs almost nothing. A quiet ongoing
 * notification is required for a foreground service.
 */
class GateService : Service() {
  private val handler = Handler(Looper.getMainLooper())
  private lateinit var store: GateStore
  private var lastForeground: String? = null
  private var lastShownFor: String? = null
  private var lastShownAt = 0L
  private var lastNote = ""

  private val tick =
      object : Runnable {
        override fun run() {
          check()
        }
      }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onCreate() {
    super.onCreate()
    store = GateStore(this)
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (!store.enabled) {
      stopSelf()
      return START_NOT_STICKY
    }
    startInForeground(noteText(System.currentTimeMillis()))
    handler.removeCallbacks(tick)
    handler.post(tick)
    return START_STICKY
  }

  override fun onDestroy() {
    handler.removeCallbacks(tick)
    super.onDestroy()
  }

  private fun check() {
    if (!store.enabled) {
      stopSelf()
      return
    }
    val now = System.currentTimeMillis()
    val window = store.activeWindow(now)
    updateNote(now)
    if (window == null) {
      val next = store.nextStart(now)
      // Wake at the next window, checking in at least every 15 minutes in
      // case the clock or the configuration changed.
      val wait = if (next == null) FIFTEEN_MIN else (next - now).coerceIn(1_000L, FIFTEEN_MIN)
      handler.postDelayed(tick, wait)
      return
    }
    val fg = foregroundPackage(now)
    if (fg != null && store.blocks(fg, now)) {
      // Do not stack screens: once per app per few seconds.
      if (fg != lastShownFor || now - lastShownAt > 4_000L) {
        lastShownFor = fg
        lastShownAt = now
        showBlockScreen(window)
      }
    } else if (fg != null && fg != packageName) {
      lastShownFor = null
    }
    handler.postDelayed(tick, POLL_MS)
  }

  /** The most recent app to come to the front, from usage events. */
  private fun foregroundPackage(now: Long): String? {
    val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val events = usm.queryEvents(now - 60_000L, now)
    val e = UsageEvents.Event()
    while (events.hasNextEvent()) {
      events.getNextEvent(e)
      if (e.eventType == UsageEvents.Event.ACTIVITY_RESUMED) lastForeground = e.packageName
    }
    return lastForeground
  }

  private fun showBlockScreen(window: GateStore.Window) {
    val i =
        Intent(this, BlockActivity::class.java)
            .addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(BlockActivity.EXTRA_REASON, window.reason)
            .putExtra(BlockActivity.EXTRA_UNTIL, window.end)
    startActivity(i)
  }

  private fun noteText(now: Long): String {
    val fmt = DateFormat.getTimeInstance(DateFormat.SHORT)
    val active = store.activeWindow(now)
    return when {
      now < store.unlockedUntil -> "Unlocked until ${fmt.format(Date(store.unlockedUntil))}"
      active != null -> "Some apps wait until ${fmt.format(Date(active.end))}"
      store.nextStart(now) != null -> "Next quiet time at ${fmt.format(Date(store.nextStart(now)!!))}"
      else -> "On, nothing planned right now"
    }
  }

  private fun updateNote(now: Long) {
    val text = noteText(now)
    if (text == lastNote) return
    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    nm.notify(NOTE_ID, buildNote(text))
  }

  private fun buildNote(text: String): Notification {
    lastNote = text
    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (nm.getNotificationChannel(CHANNEL) == null) {
      nm.createNotificationChannel(
          NotificationChannel(CHANNEL, "App gate", NotificationManager.IMPORTANCE_MIN).apply {
            description = "Shown while the app gate is on"
            setShowBadge(false)
          })
    }
    val open =
        PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    return Notification.Builder(this, CHANNEL)
        .setSmallIcon(R.drawable.ic_stat_pace)
        .setContentTitle("App gate")
        .setContentText(text)
        .setContentIntent(open)
        .setOngoing(true)
        .setShowWhen(false)
        .build()
  }

  private fun startInForeground(text: String) {
    val note = buildNote(text)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
      startForeground(NOTE_ID, note, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
    } else {
      startForeground(NOTE_ID, note)
    }
  }

  companion object {
    private const val CHANNEL = "pace_gate"
    private const val NOTE_ID = 7
    private const val POLL_MS = 1_200L
    private const val FIFTEEN_MIN = 15 * 60_000L

    /** Starts or stops the service to match the stored configuration. */
    fun sync(context: Context) {
      val store = GateStore(context)
      val intent = Intent(context, GateService::class.java)
      if (store.enabled) {
        context.startForegroundService(intent)
      } else {
        context.stopService(intent)
      }
    }
  }
}
