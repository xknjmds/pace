package com.el.pace

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter activity, plus the "com.el.pace/gate" channel the app gate
 * uses (lib/features/blocking/application/app_gate.dart).
 */
class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
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
