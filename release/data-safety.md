# Play Console: Data Safety answers (draft)

For the launch build: no calendar sync (hidden without `PACE_GOOGLE_CLIENT_ID`) and no
network use besides Google Play Billing.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable (nothing is collected) |
| Do you provide a way for users to request that their data is deleted? | Data is only on the device; uninstalling deletes it |

Notes:
- "Collected" in Play's sense means sent off the device. PACE stores everything locally.
- Google Play Billing is handled by Google and is not data PACE collects.
- If calendar sync ships later (D10), revisit this form: calendar events are fetched from
  Google, though they are only cached on the device.

## Permission declarations

- `SCHEDULE_EXACT_ALARM`: alarm-clock-style reminders at a set time (wake, leave by).
  Check the current Play policy; `USE_EXACT_ALARM` is restricted to alarm and calendar apps.
- `PACKAGE_USAGE_STATS` and `SYSTEM_ALERT_WINDOW`: the optional app gate. Needs a clear
  in-app explanation (B2 has one) and may need a declaration form and a demo video.
- `FOREGROUND_SERVICE_SPECIAL_USE`: the gate's watcher service. Play asks for a written
  justification; describe the lock windows and the always-available emergency unlock.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: Play allows it for apps whose core function breaks
  without it. Explain that reminders are the core function.
- `INTERNET`: only needed for calendar sync and billing.
