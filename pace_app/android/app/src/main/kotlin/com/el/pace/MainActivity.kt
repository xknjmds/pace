package com.el.pace

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter activity, plus the "com.el.pace/gate" channel the app gate
 * uses (lib/features/blocking/application/app_gate.dart) and the
 * "com.el.pace/device" channel for the phone maker's settings pages
 * (lib/core/platform/device_settings.dart).
 */
class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    configureDeviceChannel(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.el.pace/gate")
        .setMethodCallHandler { call, result ->
          val store = GateStore(this)
          when (call.method) {
            "permissions" ->
                result.success(
                    mapOf(
                        "usageAccess" to hasUsageAccess(),
                        "overlay" to Settings.canDrawOverlays(this)))
            "openUsageAccessSettings" -> {
              startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
              result.success(null)
            }
            "openOverlaySettings" -> {
              startActivity(
                  Intent(
                      Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                      Uri.parse("package:$packageName")))
              result.success(null)
            }
            "installedApps" -> result.success(launchableApps())
            "configure" -> {
              store.enabled = call.argument<Boolean>("enabled") ?: false
              store.unlockMinutes = call.argument<Int>("unlockMinutes") ?: 10
              store.packages =
                  (call.argument<List<String>>("packages") ?: emptyList()).toSet()
              store.windows =
                  (call.argument<List<Map<String, Any>>>("windows") ?: emptyList()).map {
                    GateStore.Window(
                        (it["start"] as Number).toLong(),
                        (it["end"] as Number).toLong(),
                        it["reason"] as? String ?: "morning")
                  }
              try {
                GateService.sync(this)
                result.success(null)
              } catch (e: Exception) {
                result.error("gate", e.message, null)
              }
            }
            "unlockedUntil" -> result.success(store.unlockedUntil)
            "unlockFor" -> {
              store.unlockFor(call.argument<Int>("minutes") ?: store.unlockMinutes)
              result.success(null)
            }
            else -> result.notImplemented()
          }
        }
  }

  private fun configureDeviceChannel(flutterEngine: FlutterEngine) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.el.pace/device")
        .setMethodCallHandler { call, result ->
          when (call.method) {
            "manufacturer" -> result.success(Build.MANUFACTURER ?: "")
            "openAutoStart" -> result.success(openAutoStart())
            "openAppDetails" -> {
              openAppDetails()
              result.success(null)
            }
            "screenEvents" -> {
              val from = (call.argument<Number>("from") ?: 0).toLong()
              val to = (call.argument<Number>("to") ?: 0).toLong()
              result.success(screenEvents(from, to))
            }
            else -> result.notImplemented()
          }
        }
  }

  /**
   * Brand auto-start pages. They are private screens of each maker's
   * security app and move between versions, so each is only tried; the
   * app info page is the fallback.
   */
  private val autoStartPages =
      listOf(
          "com.miui.securitycenter" to
              "com.miui.permcenter.autostart.AutoStartManagementActivity",
          "com.coloros.safecenter" to
              "com.coloros.safecenter.permission.startup.StartupAppListActivity",
          "com.coloros.safecenter" to
              "com.coloros.safecenter.startupapp.StartupAppListActivity",
          "com.oplus.safecenter" to
              "com.oplus.safecenter.permission.startup.StartupAppListActivity",
          "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
          "com.vivo.permissionmanager" to
              "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
          "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
          "com.huawei.systemmanager" to
              "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
          "com.huawei.systemmanager" to
              "com.huawei.systemmanager.optimize.process.ProtectActivity",
          "com.transsion.phonemaster" to "com.cyin.himgr.autostart.AutoStartActivity",
      )

  private fun openAutoStart(): Boolean {
    for ((pkg, cls) in autoStartPages) {
      try {
        startActivity(
            Intent().setComponent(ComponentName(pkg, cls))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return true
      } catch (_: ActivityNotFoundException) {
      } catch (_: SecurityException) {}
    }
    openAppDetails()
    return false
  }

  private fun openAppDetails() {
    try {
      startActivity(
          Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
              .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    } catch (_: ActivityNotFoundException) {
      startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
  }

  /**
   * Screen on, unlock and screen off moments between [from] and [to] (epoch
   * ms), for the sleep check spike (D8). Needs usage access; without it, or
   * before Android 9, the list is empty. Nothing leaves the phone.
   */
  private fun screenEvents(from: Long, to: Long): List<Map<String, Any>> {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P || !hasUsageAccess()) {
      return emptyList()
    }
    val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val events = usm.queryEvents(from, to)
    val out = mutableListOf<Map<String, Any>>()
    val e = UsageEvents.Event()
    while (events.hasNextEvent()) {
      events.getNextEvent(e)
      val on =
          when (e.eventType) {
            UsageEvents.Event.SCREEN_INTERACTIVE,
            UsageEvents.Event.KEYGUARD_HIDDEN -> true
            UsageEvents.Event.SCREEN_NON_INTERACTIVE -> false
            else -> null
          } ?: continue
      out.add(mapOf("t" to e.timeStamp, "on" to on))
    }
    return out
  }

  private fun hasUsageAccess(): Boolean {
    val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
    val mode =
        ops.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
    return mode == AppOpsManager.MODE_ALLOWED
  }

  /** Apps with a launcher icon, except PACE itself. */
  private fun launchableApps(): List<Map<String, String>> {
    val pm = packageManager
    val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    return pm.queryIntentActivities(launcher, 0)
        .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
        .filter { it.first != packageName }
        .distinctBy { it.first }
        .map { mapOf("package" to it.first, "label" to it.second) }
  }
}
