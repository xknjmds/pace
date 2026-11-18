package com.el.pace

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts the app gate after a reboot or an app update, if it is on. */
class GateBootReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (GateStore(context).enabled) GateService.sync(context)
  }
}
