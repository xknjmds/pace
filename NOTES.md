# NOTES.md

Device findings and decisions that are not obvious from the code.

## M2. Notification spike

### How to run the check (real phone, not emulator)

1. Install the debug APK, open PACE, choose More > Reminders.
2. Grant the three steps: notifications, exact timing, battery optimisation off.
3. Tap "Send test reminder", lock the phone, wait one minute. Expect it on the minute.
4. Send another test, swipe PACE away from Recents, lock the phone, wait.
5. Send another test, reboot the phone before it is due, leave it locked, wait.
6. Record the results below. Useful while debugging:

```sh
adb shell dumpsys alarm | grep -A3 com.el.pace        # pending alarms
adb shell dumpsys deviceidle whitelist | grep com.el.pace   # battery exemption
adb shell cmd appops get com.el.pace SCHEDULE_EXACT_ALARM
```

### Results

| Check | Result | Notes |
|---|---|---|
| Phone model, Android version | not yet run | |
| Fires on time, screen off | not yet run | |
| Fires after app swiped away | not yet run | |
| Fires after reboot | not yet run | |

### Decisions

- **Toolchain bumped for the notification plugins.** permission_handler_android 14.1 and
  flutter_local_notifications 23.0 compile against API 37, and their AndroidX core 1.19
  dependency needs Android Gradle Plugin 9.1. So: app `compileSdk = 37` (Flutter's default is
  36), AGP 9.0.1 to 9.1.1, Gradle wrapper 9.1.0 to 9.3.1 (AGP 9.1's minimum). The SDK repo
  offers API 37 only as minor-versioned packages; `platforms;android-37.0` resolves as
  `android-37`. Install it with `sdkmanager --install "platforms;android-37.0"` on a new machine.
- **Exact alarms use `SCHEDULE_EXACT_ALARM`, requested from the Reminders screen.** On
  Android 14+ this opens the system "Alarms & reminders" page; on 12 and 13 it is granted at
  install; below 12 it does not exist. The alternative, `USE_EXACT_ALARM`, is granted silently
  but is reserved for alarm-clock and calendar apps under Play policy. PACE is sideloaded, so it
  would work, but the plan asked for an explained request. If the permission is denied, the
  gateway falls back to an inexact alarm and the screen says so, rather than sending nothing.
- **Reboot rescheduling is the plugin's.** `ScheduledNotificationBootReceiver` (declared in
  the app manifest) re-registers every pending notification from the plugin's own store on
  `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED`. If exact alarms were revoked while off, the
  plugin logs and drops that notification. From M3 the `scheduled_notifications` table is the
  source of truth, so the app should also rebuild from data on launch rather than trust the
  plugin's store alone.
- **Core library desugaring** is on in `android/app/build.gradle.kts`; the plugin needs
  `java.time` on API 26.
- **Notification id 1 is hard-coded** in `core/notifications/notification_ids.dart` for the test
  reminder only. M3 replaces this with table-backed ids (CLAUDE.md rule 2).
- **Time zone:** `flutter_timezone` resolves the device zone for `timezone`; if the name is
  unknown the gateway logs and keeps UTC, which is still correct because reminders are
  scheduled from an absolute instant.

## M4. Leave-by planner

### Still to check on the phone

| Check | Result | Notes |
|---|---|---|
| Wake, eat, leave fire at the times shown in Settings | not yet run | |
| "Done", "10 more minutes", "Not today" buttons work from the lock screen | not yet run | each opens the app, see below |

### Decisions

- **Morning order is wake, free time, breakfast, getting ready, leave**, laid out backwards
  from the first class. The target wake time is kept whenever it is early enough, because a
  steady wake time is the point; when it is too late the plan uses the latest workable time
  and says so gently. When there is no free time, breakfast folds into the wake reminder so
  two notifications do not land on the same minute.
- **Reminders are planned seven days ahead, one owner per weekday** (`"1"` to `"7"`), and
  re-planned on every launch and after every settings or schedule change. A snooze is a
  separate owner (`"1:snooze"`) so it cannot stack and does not disturb the plan.
- **Notification buttons open the app**, which then applies the action in the main isolate.
  Handling them in the plugin's background isolate (no app launch) needs database and plugin
  access from that isolate and could not be verified without a device. Revisit after the
  M2 checks pass; the `ReminderResponseRouter` in `core/notifications` is the seam.
- **"Not today" writes a `reminder_mutes` row** and re-plans. Nothing is logged, nothing is
  marked done, and the next week's reminder appears as soon as it enters the 7-day window.
