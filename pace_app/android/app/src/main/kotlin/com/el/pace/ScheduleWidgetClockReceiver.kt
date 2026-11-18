package com.el.pace

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * After a reboot, an app update or a clock change, asks the classes widget
 * to redraw and set its next alarm (alarms do not survive a reboot).
 */
class ScheduleWidgetClockReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    context.sendBroadcast(
        Intent(context, PaceScheduleWidgetProvider::class.java)
            .setAction(PaceScheduleWidgetProvider.ACTION_TICK))
  }
}
