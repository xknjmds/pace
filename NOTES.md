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

## M5. Deadline tracker

### Decisions

- **Nudge times.** Three days before and one day before land at 19:00; the morning-of nudge
  lands 30 minutes after the target wake time so it never shares a minute with the wake
  reminder; the last one is two hours before the due time. Nudges already past, after the
  deadline itself, on a muted day, or on the same minute as another are dropped. A deadline
  under two hours away may get no nudge at all, by design.
- **Owner id is the task id.** Submitting cancels the owner; editing re-plans it; "Not today"
  (notification button or tile menu) writes a `reminder_mutes` row for that task and day and
  re-plans. The task stays pending.
- **Past due is quieter, not louder.** The "Still open" section uses a tinted surface and an
  italic subtitle, never the error colour. Low-energy mode shows only tasks due within 48
  hours and hides the Submitted list.

## M6. Today screen

### Decisions

- **One pure function decides the routine card** (`features/today/domain/today_model.dart`):
  no class, does not fit, steps remaining with the next one named, running late, or all
  done. The late card appears only while the owner is not up, more than
  `late_threshold_minutes` past the planned wake, and less than an hour into the first class;
  after that the plain step list returns. Its copy never contains the word "late".
- **"I'm out the door"** on the late card logs wake and marks the routine done in one tap;
  breakfast stays open so the owner can still log it.
- **Step chips call the same `done` path as the notification buttons**, so Today and the
  lock screen agree on what was logged.
- **Due soon** shows pending tasks due within 48 hours, overdue included, capped at three
  with an "and N more" line. The top-3 picker allows at most three and saves to `daily_logs`.
- **Low-energy mode** hides Top 3, the eat step and the tomorrow line; the toggle stays on
  Today. Verified to fit a 360x640 phone without scrolling in the widget tests.

## M7. Quick capture

### Still to check on the phone

| Check | Result | Notes |
|---|---|---|
| Kotlin widget provider and manifest compile (`flutter build apk`) | not yet run | disk too full to build; nothing Android-side has been compiled |
| Widget can be added; shows the inbox count; count updates after capturing | not yet run | |
| "Write it down" on the widget opens the Inbox with the keyboard up | not yet run | cold start and while running |
| Reply in the capture notification saves without opening the app | not yet run | background isolate, see below |
| Capture notification is silent and does not buzz on every refresh | not yet run | low-importance channel |

### Decisions

- **Two ways to capture without the app's main screen.** The home-screen widget opens PACE
  straight into the Inbox with the field focused (`pace://capture`). The optional, quiet
  "Got a thought?" notification has an inline reply field. Text typed there goes in
  without opening the app. A widget cannot take text input on Android, so the notification
  is the only way to capture without opening anything. It is on by default and can be
  turned off on the Inbox screen.
- **Inline replies run in the notification plugin's background isolate**
  (`captureFromNotificationBackground`). That engine registers all plugins, so it opens
  its own Drift connection to the same file, saves the item, re-shows the shortcut (which
  clears Android's "sending" state), refreshes the widget and closes the connection. Two
  connections to one SQLite file is fine for these single-row writes, but it has not been
  seen working on a device.
- **The widget is plain RemoteViews** (no Glance), in Sand and Moss with a dark variant.
  It shows only the inbox count and one button, so it never needs a scheduled refresh.
  The count is pushed whenever the inbox changes.
- **Schema v3** adds `settings.capture_shortcut_enabled` (default on), with a migration test
  from both v1 and v2.
- **Low-energy mode** folds the Inbox list into one line ("N things waiting. They can
  wait."), and capturing still works.

## M8. "Just start" timer

### Still to check on the phone

| Check | Result | Notes |
|---|---|---|
| Timer completes with the screen off and the "10 minutes done" notification arrives on time | not yet run | exact alarm through the scheduler, no foreground service |
| "Stop here" / "Keep going" on that notification | not yet run | both open the app, like the routine buttons |

### Decisions

- **No foreground service, no new dependency.** A session stores `started_at` and the planned
  minutes; the countdown is worked out from the wall clock whenever the screen looks, and the
  time-up alert is an exact scheduled notification (owner = session id). Screen off, app
  killed or phone rebooted, the answer is the same. The trade-off: no live countdown in the
  notification shade.
- **Schema v4 adds `focus_sessions.ended_at`.** A null value means the session is live,
  either running or past its end and waiting for a choice. Sessions from before v4 are
  marked ended at their start time.
- **Recorded minutes are time actually focused.** Stopping early records whole minutes
  spent. Stopping after the alarm records the planned 10, never the idle time after it.
  "Keep going" ends the first session as completed and starts a fresh 10 minutes from now,
  so two rows hold 10 + 10 rather than one row with the gap included.
- **Only 10 minutes is offered.** The point is that starting is small. Stopping early is
  met with "That counts", never a failure state.
- **Entry points:** Focus in the Today menu, "Just start" in each deadline's menu
  (preselects the task), and a "Focus: N min left" line on Today while a session is live.
  In low-energy mode the task picker lists only tasks due within 48 hours.

### Fixed: upgrades from v1 were broken since M3

The v1 to v2 step created tables from their *current* Dart definitions, so once v4 added a
column to `focus_sessions`, a v1 to v4 upgrade created it with `ended_at` already present
and then failed adding it again. Migrations now use Drift's `stepByStep` with schemas
frozen per version (`lib/core/db/schema_versions.dart`, generated from `drift_schemas/`).
Each step does the same thing as before. No installed copy existed (the app has never been
built), so no real data was affected. Regenerate the steps file after every schema dump.

## M9. Evening check-in and sleep log

### Still to check on the phone

| Check | Result | Notes |
|---|---|---|
| Wind-down notification arrives at bedtime minus lead time, showing tomorrow's first item | not yet run | |
| "Going to bed" on the notification logs bed for the right night | not yet run | before noon counts as the night before |
| Tapping the wind-down notification opens the check-in, with Today behind it | not yet run | Today is now the root route `/` |

### Decisions

- **Bedtime is derived, never set.** Night D's bedtime is the next morning's wake time
  minus the sleep target. Wind-down is that minus the lead time. Change the wake time
  and both follow.
- **The wake anchor applies once the week is set up.** Every day gets a wake reminder,
  including days without class. Before any weekday is configured, nothing fires.
- **Weekend wake** is the weekday wake plus a lie-in of 0 to 60 minutes (default 60, capped
  at 60 even if the column says more). It follows any shift under way.
- **Gradual shift** moves the weekday wake earlier by 15 minutes every 3 calendar days from
  the day it started, and stops exactly at the goal. It is computed from the calendar
  alone, so a missed or late night can neither reset nor stall it. Once the goal is
  reached, the next resync makes it the plain wake time and clears the shift. A goal that
  is not earlier applies at once, and setting the wake time by hand stops any shift.
- **Check-in:** tomorrow (wake, leave, class, anything due within 48 hours), top 3 for
  tomorrow, the wake reminder with a warning if reminders are off or inexact, then "Going to
  bed". Every step can be skipped. Low-energy mode drops the top-3 step.
- **Today** shows an evening card from wind-down until four hours past bedtime, unless bed
  is logged, and an "I'm up" chip on days without class.
- **Schema v5** adds weekend leeway and the shift columns to `settings`.

## M10. Low-energy mode and weekly view

### Decisions

- **Low-energy mode changes reminders, not just screens.** When it is on, only wake and
  leave fire (no breakfast, no wind-down), and deadline nudges are limited to the last 48
  hours. Every toggle (Today, Settings) goes through one provider that saves the setting
  and re-plans all reminders, so Today and the notification shade always agree. Screens
  already followed it: Today, Deadlines, Inbox and Focus since M6 to M8, and now
  Check-in and Review.
- **Weekly view** covers the last 7 days. It shows days with the routine done, the average
  logged wake time and how many mornings it comes from, the average length of nights where
  both ends were logged, and a sleep log of every night with anything logged ("bed not
  logged" rather than a gap). Empty data reads "No ... logged yet". No streaks, no red, and
  no number ever goes down because of a missed day. In low-energy mode the sleep log folds
  into a count with a Show button.
