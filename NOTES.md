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

## First real-device install (2026-11-18)

The owner installed a release APK (`flutter build apk`, built 14:28 from commit 09d96e3) and
it did not work. No phone was connected afterwards, so there are no device logs. Reading
the APK found the cause: **`drawable/ic_stat_pace` was missing**. Release builds shrink
resources, and the notification icon is only named from Dart, so R8 removed it.
`LocalNotificationGateway.initialize()` then fails ("invalid icon") inside `main` before
`runApp`, so the app never draws a screen. The four densities exist in the source, and the
release APK's resource table has no entry for them.

Fixes:
- `res/raw/keep.xml` keeps `@drawable/ic_stat_pace`, as the plugin's README requires.
  Its R8 rules for Gson ship with the plugin since v19, so no proguard file is needed.
- Startup can no longer stop the app from opening. `main` and `bootstrap` run each step
  (notifications, rebuild, routine, deadlines, widget, capture, launch response) through
  `StartupReport.guard`, so a failure is logged and recorded and the next step still runs.
  Today shows one calm card, "Reminders did not start properly", linking to the reminder
  setup.

Not yet confirmed on the phone: a new release build is needed (disk at 1.2 GB free).

## Web and desktop (2026-11-18)

The owner asked for PACE to run on all devices and chose Android + web + desktop (no iOS).

- **What runs where.** Everything runs everywhere: Today, deadlines, inbox, focus, check-in,
  review and settings. Reminders, notification buttons, the shade capture shortcut and the
  home-screen widget are Android-only. Elsewhere `main` uses `NoopNotificationGateway` and
  `NoopHomeWidgetBridge`, which succeed quietly, so startup, the scheduler and the
  `scheduled_notifications` table behave the same. `platformFeaturesProvider` hides or
  rewords the Android-only parts: the Reminders menu entry and screen, the Inbox shortcut
  switch, the Focus screen-off line, the check-in alarm step and the wind-down subtitle.
- **Web database.** drift runs SQLite in a worker: `web/sqlite3.wasm` (from the sqlite3.dart
  release matching sqlite3 3.5.2) and `web/drift_worker.js` (compiled from
  `tool/drift_worker.dart` against the locked drift). Without special server headers it
  uses IndexedDB, which is fine.
- **Desktop database** lives in the per-app data folder (`path_provider`, now a direct
  dependency at the already-locked 2.1.6, approved by the owner), not drift's default of
  ~/Documents.
- **Verified here:** `flutter build web` loaded in headless Chrome through the debugging
  protocol. The database opened with no exceptions, Today rendered, low-energy mode
  survived a reload, and Settings showed the web wording. `flutter build linux` ran for 10
  seconds with no errors and created its database in ~/.local/share/com.el.pace.
  `flutter build apk --release` succeeds and now contains `drawable/ic_stat_pace` in all
  densities.
- **Not verified:** Windows and macOS builds need those systems. The new APK has not been
  run on the phone yet.

## v2 (2026-11-18)

The owner asked for all of v2 at once rather than one milestone at a time. The code for
phases A, B and C is in, with unit and widget tests (316 pass). **Neither spike has been run on
a real phone**, so A2 and B1 are not done in the PLAN.md sense.

- **Schema v6** (one step, `from5To6`): `class_blocks`, `habits`, `habit_logs`, `blocked_apps`,
  `notes`, `expenses`, `budgets`, `calendar_events`. Settings gains the verse, currency, gate
  and calendar fields, and `tasks` gains `submitted_at`. The planned `blocking_settings` table
  became settings columns, so there is still only one single-row table.
- **A1 verse.** `assets/verses.json` holds 365 verses from the World English Bible (public
  domain). They were pulled from the eBible.org text (`engwebp_vpl`) by reference, not typed
  from memory. They appear on Today and as a line in the wake reminder, which now uses
  Android's expanded text style.
- **A2 OCR spike: PENDING.** `google_mlkit_text_recognition` uses the bundled Latin model
  (`com.google.mlkit:text-recognition`), so nothing is downloaded. Release builds need the
  `-dontwarn` rules in `android/app/proguard-rules.pro` for the optional language models that
  are not included. To do on the phone: photograph the real schedule, then record here how
  well `parseSchedule` reads it (list layout, grid layout, MWF/TTh codes). If it reads poorly,
  write that down; adding blocks by hand already works.
- **A4 widget.** `PaceScheduleWidgetProvider` sets its own alarm for the next block boundary
  or midnight. `ScheduleWidgetClockReceiver` re-arms it after a reboot, an app update or a
  clock change. Not yet checked on a home screen.
- **B1 blocking spike: PENDING.** It uses usage access plus a block screen. The block screen is
  an activity started from a `specialUse` foreground service and needs "display over other
  apps". It does not use an AccessibilityService. The service polls every 1.2 s only inside a
  lock window and otherwise sleeps until the next one. To do on the phone: block one test app
  with battery optimisation on and the screen locked for a while, then check it survives a full
  day and a reboot, and record the result and phone model here. **Stop before relying on B2 if
  it is unreliable.** Play note for M11: `specialUse` needs a justification at review, and
  `PACKAGE_USAGE_STATS` is a special permission the user grants.
- **C3 calendar.** Build with `--dart-define=PACE_GOOGLE_CLIENT_ID=<web client id>`. Without
  it, the Calendar screen explains the setup and nothing goes online. Android also needs the
  app's SHA-1 registered in the same Google Cloud project, and the Calendar API enabled. While
  the OAuth app is in "Testing", Google expires the grant after 7 days, so "Reconnect" will
  show up weekly. On the web the access token lasts an hour. Refresh happens on launch and on
  resume when the cache is over an hour old; there is no background job, because WorkManager
  would be another dependency. Desktop has no Google sign-in plugin, so it is hidden there.
- **Verified here:** `flutter analyze` is clean and `flutter test` passes. `assembleDebug` and
  `assembleRelease` both build, the release with R8 and resource shrinking. Gradle needed
  `-Dorg.gradle.jvmargs=-Xmx3g`, because the 8 GB in gradle.properties does not fit this
  machine's free memory.
- **Not verified:** everything on a device. That covers the habit and wake/verse
  notifications, the widget, the gate, OCR on a real photo, Google sign-in (no client id
  here), and the web build of the new screens.

## Phase D (2026-11-19, built overnight while the owner was away)

### D1. First-run setup
- A fresh install opens on `/setup` over Today (decided in `main.dart`, so widget and
  notification launches still win). Back without finishing shows it again next launch;
  "Skip for now" and "Looks good" both set `onboarded_at`. The v7 to v8 migration marks
  existing installs as set up, so the owner's phone never sees it.
- One first-class time for all chosen days. Per-day times stay in Settings, as before.
- A usual wake within 30 min of the workable goal is applied at once; a bigger gap starts
  the existing gradual shift (15 min every 3 days, night people 10 min every 4).
- **Not verified on a device.**

### D2. Recovery, mood, welcome back, steady mode
- **Light day** is `settings.light_day_date`. Every planner and `lowEnergyProvider` now read
  `Setting.lowEnergyAt(now)` (`core/energy/low_energy.dart`). Known limit: planners take one
  low-energy flag for their whole 7-day window, so if reminders are re-planned *during* a
  light day, the following days stay light until the next re-plan (any app open). Planning
  tonight for a light day tomorrow does not lighten tomorrow's reminders; Today does.
- **Welcome back** after 5+ calendar days without opening: light day plus a card, set in
  `noteOpened()` at the start of `bootstrap` and on resume. The gap is never shown.
- **Steady mode** passes the low-energy short set to the routine reminder planner only (wake
  and leave). Habit, deadlines and the gate are unchanged. Offered on Review after 12
  routine-done days in 21, hidden in low-energy mode; "Not now" waits 60 days.
- **Help page numbers must be checked before every release**
  (`features/wellbeing/domain/support_contacts.dart`): 911, NCMH 1553 and mobiles, Hopeline
  PH. They came from memory, not from a live source. There is no tap-to-call, because that
  needs `url_launcher` (a new dependency); the numbers are selectable text.
- The local `test/zz_shots` goldens for the late card (`late0748`, `late0804`) now differ,
  because the card shows recovery tips. Regenerate them with `--update-goldens` if the new
  look is right.

### D3. Reliable reminders on brand phones
- Built into the existing Reminders screen (`core/notifications/ui/notification_setup_screen.dart`),
  which already had notifications, exact timing, battery optimisation and the one-minute test
  reminder. The first-run setup now ends there on Android.
- New: a brand card from `guideFor(Build.MANUFACTURER)` for Xiaomi/Redmi/POCO,
  OPPO/realme/OnePlus, vivo, Infinix/TECNO/itel, Huawei/Honor and Samsung, through the new
  `com.el.pace/device` channel. "Open auto-start" tries each maker's private settings
  activity in turn and falls back to App info. Those activity names move between OS versions;
  any that fail just fall through.
- **Verified here:** `assembleDebug` compiles the Kotlin.
- **Not verified:** that any auto-start page actually opens, and that the test reminder fires
  with the screen locked on the owner's phone **and on a budget Xiaomi or OPPO phone**. This
  is the D3 "done when" and it is still open.

### D5. Tuck's journey
- Derived from logs, with no table: distinct days with the routine done, movement done or a
  deadline handed in. Stops run to day 365, then "Open sea" every 100 days. Firsts are
  personal only (no ranking).
- Entry points: a pill on Today (hidden in low-energy mode and before the first day) and a
  tile on Review. The screen shows only the top card in low-energy mode.
- Because it is derived, un-marking a routine day or deleting a habit log takes that step
  back out. That only undoes the owner's own correction, never a missed day.
- No new mascot art: it uses the existing poses. The path is a plain list for now; a drawn
  path is a nice later polish.

### D6. Self-set rewards
- `rewards` table (v10): title, days needed, created, claimed. Progress counts the same done
  days as the journey, from the day the reward was set (that day included), so old history
  never auto-earns a new reward. An unclaimed reward never expires.
- "Log the cost" opens Money; it does not create an expense itself, so finance stays
  independent (rule 13).
- Removing is soft with Undo, which restores the same row with its days intact.
- Low-energy mode lists only rewards that are ready to enjoy.
- Entry points: More (Journey and Rewards tiles, plus "If you're struggling" in the App
  group) and the Journey screen.

### D7. Next routine and the school year
- After 12 routine days in 21, Review offers one idea at a time: a steady bedtime (fewer
  than 5 bedtimes logged in 14 days), then study time (fewer than 3 focus sessions), then a
  budget (none set). "Not now" is remembered in `settings.dismissed_suggestions` (v11).
  Hidden in low-energy mode.
- Your school year (`/review/year`, from Review): totals since the 1st of the start month
  (`settings.school_year_start_month`, June by default, changeable on the screen). Positive
  totals only, no rates.
- **Not built:** exporting the year as an image. Sharing needs `share_plus` (or saving needs a
  file-picker plugin), and both are new dependencies to ask about first.

### D8. Activity spike (sleep check only)
- Built: `estimateSleep` (pure, tested). Between 20:00 and noon it finds the longest stretch
  with the screen off, ignoring pickups under 3 minutes (checking the time), and needs at least
  2 h; 4 h or more reads as "confident". Screen events come from usage access (the gate's
  existing permission) via `screenEvents` on the `com.el.pace/device` channel. Nothing is
  stored.
- Test screen: Settings > Extras > "Sleep check (test)" shows the last three nights, logged
  bed and wake beside the phone's quiet stretch.
- **Not built, waiting on the owner:**
  - Step counter: needs the `ACTIVITY_RECOGNITION` permission. Ask first.
  - Google Sleep API: needs `play-services-location`, a new dependency. Ask first.
- **To do on the phone (the spike's "done when"):** write down real sleep and wake times for
  three nights, compare them with the test screen, and record accuracy and phone model here.
  **D9 (suggestions) waits for that result** (CLAUDE.md: stop after a spike to report).
- **Verified here:** `assembleDebug` compiles. A stale Gradle daemon broke the plugin loader
  once; `./gradlew --stop` fixed it.

## Schedule photo: time-block grids (2026-11-20)

The owner's real schedule (`pace_app/test/fixtures/schedule_time_block.jpg`) is a
spreadsheet-style time-block grid, and the old parser read it poorly: every text line became a
class, boxes got one row's time, and the summary table under the grid was read as more classes.

- **Text layer** (`schedule_grid.dart`): grid bounds come from the day header and the time
  labels; anything under the last time row is cut. Range labels ("8:00 - 8:30") and single
  hour labels ("7:00") both work. When the schedule prints course codes, each code opens a
  class and the title, room and teacher lines join it. The room comes from "BH101 - PROF. …"
  style lines (also LAB/ROOM/AVR/ONLINE); teacher names are dropped. Breaks are skipped.
- **Pixel layer** (`schedule_boxes.dart`): the reader also decodes the photo with `dart:ui`
  (no new package). The time column is split at its border lines into true rows, each day
  column into coloured runs, using the per-channel median of pixels outside the text boxes.
  Each box's top and bottom map to row times, which gives the full span (Friday ITAS3123
  8:00 to 11:00). It falls back to the text layer if the pixels don't match the text's size,
  the rows don't match the labels, or it finds under half the text layer's classes.
- **Fixture test:** all 24 classes on the real schedule come out right with pixels. Text alone
  gets every day, subject and room, but only approximate times for centred text.
- The OCR fixture was transcribed by hand with positions measured from the image (no OCR tool
  here). Real ML Kit output may split lines differently. In debug builds, the review screen's
  "Copy scan data" button copies the real lines as JSON, to add as a second fixture.
- **Not verified on a phone:** a real ML Kit read of this screenshot, and a tilted photo of
  the printed schedule (it should fall back to the text layer).
