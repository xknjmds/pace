# PACE developer guide

This guide covers how PACE is built, how its parts fit together, and how to change it
safely. Read it alongside the three files at the repo root:

| File | What it holds |
|---|---|
| `CLAUDE.md` | The project rules. They are binding, and this guide only explains them |
| `PLAN.md` | Milestones (M1 to M10, v2 phases A to C, v2.1 fixes, M11) with acceptance criteria |
| `NOTES.md` | Device findings and decisions not obvious from the code, and what is still unverified |

---

## 1. Principles

PACE is a single-user, offline-first routine app for one owner who is recovering from
burnout. Every feature must answer: *does this help the owner start the right thing at the
right time?* The rules that shape the code:

1. **Scheduling logic is pure Dart.** No Flutter, Drift or plugin imports in `domain/`.
   Every function there is unit tested.
2. **Notifications are rebuilt from data.** Every scheduled notification is a row in
   `scheduled_notifications` with a kind and an owner id. Change reminders by cancelling an
   owner and rescheduling. Nothing else touches notification ids.
3. **Offline-first.** The one network call is optional, read-only Google Calendar sync.
4. **Forgiving by design.** No red failure states, no streaks that reset, positive counts
   only. Copy is calm and never rushes or shames.
5. **Low-energy mode** is respected by every screen, widget and reminder planner.
6. **Sync-ready schema.** `updated_at` and `deleted_at` on every table, soft deletes, UUID
   keys. No `user_id` until M11.
7. **OCR is never trusted** (imports are reviewed before saving), and **blocking is always
   escapable** (emergency unlock and a master switch).
8. **Finance, notes and calendar are independent.** They never import routine code.

## 2. Repository layout

```
pace/
  CLAUDE.md  PLAN.md  NOTES.md
  branding/          Tuck the turtle: guidelines, source art, build_mascot.py
  docs/              This documentation (Markdown, images, PDF build script)
  pitch/             Pitch deck and scripts (not part of the app)
  pace_app/          The Flutter project
    lib/
      main.dart      Entry point: platform gateways, startup, runApp
      startup.dart   bootstrap(): brings reminders, widgets and gate in line with data
      app.dart       PaceApp (MaterialApp, theme, navigator key)
      routes.dart    Named routes and the cold-start stack
      core/          Shared code (see section 4)
      features/      One folder per feature (see section 5)
    test/            Mirrors lib/
    android/         Android host app, widgets and the app gate (Kotlin)
    web/             sqlite3.wasm and drift_worker.js for the web database
    linux/ macos/ windows/
    drift_schemas/   Frozen JSON schema per database version
    tool/            build_web_db.sh, drift_worker.dart
    assets/          verses.json, Figtree fonts, Tuck PNGs
```

There is deliberately no `ios/` folder. Do not add iOS code or config.

## 3. Getting set up

**Requirements**

- Flutter with Dart SDK `^3.12.2`.
- Android SDK with platform API 37. The SDK repo offers it as a minor-versioned package:
  `sdkmanager --install "platforms;android-37.0"`.
- Chrome for the web build. Linux desktop needs the usual Flutter Linux toolchain.

**Common commands** (run in `pace_app/`)

```sh
flutter pub get
dart run build_runner build          # Drift and Riverpod code generation
flutter run                          # pick an Android device, Chrome or Linux
flutter test
flutter analyze
dart format .
flutter build apk --release
flutter build web
flutter build linux
```

Calendar sync needs an OAuth client id at build time (see section 10):

```sh
flutter run --dart-define=PACE_GOOGLE_CLIENT_ID=<web client id>
```

If Gradle runs out of memory, pass `-Dorg.gradle.jvmargs=-Xmx3g`. The 8 GB in
`gradle.properties` is more than some machines have free.

## 4. Architecture

### Layers inside a feature

Each feature folder under `lib/features/` uses the same three layers:

| Layer | Contains | May import |
|---|---|---|
| `domain/` | Pure functions and plain data classes: planners, parsers, summaries | Dart only, plus `core/time` and `core/check_in` |
| `application/` | Riverpod providers and services that read the database, call domain functions, and hand drafts to the reminder scheduler | Drift, plugins, `core/` |
| `ui/` | Screens, sheets and feature-local widgets | Everything above |

Shared UI lives in `core/widgets` and `core/theme`. Keep widgets small and feature-local
unless two features need them.

### State

Riverpod 3 (`flutter_riverpod`, `riverpod_annotation`). The app runs in one
`ProviderContainer` built in `startup.dart` (`containerFor`), which overrides the
notification gateway, the home-widget bridge and the startup report with the real or no-op
versions for the current platform. Tests override the same providers.

Time comes from `core/time/clock.dart` so tests can freeze it. Times of day are
`LocalTime` (minutes since midnight). Instants are stored in UTC and converted at the edge.
Calendar days are `yyyy-MM-dd` keys (`core/time/date_key.dart`).

### Startup

`main()` runs in this order, and nothing in it can stop the app from opening:

1. Pick gateways from `PlatformFeatures.current()`: `LocalNotificationGateway` and
   `HomeWidgetBridgeImpl` on Android, `NoopNotificationGateway` and `NoopHomeWidgetBridge`
   elsewhere.
2. Initialise notifications.
3. `bootstrap()` (in `startup.dart`) runs each step through `StartupReport.guard`, so a
   failure is logged and the next step still runs:
   rebuild reminders from the table, load verses, plan routine, plan deadlines, plan the
   habit, sync the app gate, publish the schedule widget, publish the inbox count and the
   capture shortcut. Calendar refresh is started but not awaited.
4. Subscribe to live changes: the inbox count feeds the widget, a finished morning routine
   re-syncs the gate, and app resume re-syncs the gate and refreshes a stale calendar.
5. Route the launch: a notification tap, a widget tap, or Today.

If any step failed, Today shows one calm card, *"Reminders did not start properly"*, with a
link to the reminder setup. This exists because a release build once crashed before
`runApp` (see `NOTES.md`, "First real-device install").

### Navigation

`routes.dart` defines named routes. Today, Deadlines, Inbox, Focus and More are tabs of
one `HomeShell`, which is always the root. Every other screen is pushed on top, so a cold
start into, say, the evening check-in still has the shell underneath
(`Routes.initialStack`). While the app runs, `Routes.open` switches tabs or pushes a screen
through `shellRequestProvider`.

| Route | Screen |
|---|---|
| `/`, `/deadlines`, `/inbox`, `/focus`, `/more` | Shell tabs |
| `/capture` | Inbox tab with the field focused (widget and shortcut) |
| `/review`, `/review/check-in` | Review, evening check-in |
| `/settings`, `/notifications` | Routine settings, reminder setup |
| `/schedule`, `/gate`, `/notes`, `/money`, `/calendar` | v2 screens |

### Platform differences

All platform checks go through `core/platform/platform_features.dart`. Never scatter
`Platform.isAndroid` checks through the code.

| Capability flag | Android | Web | Desktop |
|---|---|---|---|
| `reminders` (scheduled notifications, buttons, capture shortcut) | yes | no | no |
| `homeWidget` | yes | no | no |
| `scheduleImport` (ML Kit OCR) | yes | no | no |
| `appBlocking` | yes | no | no |
| `calendarSync` | yes | yes | no |

Screens read `platformFeaturesProvider` to hide or reword Android-only parts. The no-op
gateways succeed quietly, so the scheduler and the `scheduled_notifications` table behave
the same on every platform. iOS and Fuchsia show `UnsupportedPlatformApp`.

## 5. Feature map

| Folder | What it does | Key files |
|---|---|---|
| `routine` | Weekday schedule, leave-by plan, wake anchor, gradual shift, routine reminders | `domain/morning_plan.dart`, `domain/wake_schedule.dart`, `domain/routine_reminder_planner.dart`, `application/routine_reminders.dart` |
| `today` | Today screen: routine card, timeline, top 3, coming up, evening card | `domain/today_model.dart`, `domain/day_timeline.dart`, `ui/today_screen.dart` |
| `deadlines` | Tasks, nudge times, submit and let-go | `domain/deadline_reminders.dart`, `application/deadline_reminders_service.dart` |
| `inbox` | Quick capture, widget count, shade shortcut with inline reply | `application/inbox_capture.dart`, `application/capture_background.dart` |
| `focus` | Ten-minute "just start" sessions from the wall clock | `domain/focus_timer.dart`, `application/focus_service.dart` |
| `review` | Evening check-in, weekly view, four-week trends | `domain/weekly_summary.dart`, `domain/trends.dart` |
| `verse` | Daily verse from `assets/verses.json` | `domain/verse.dart` |
| `schedule` | Class blocks, photo import and review, schedule widget data | `domain/schedule_parser.dart`, `application/schedule_service.dart` |
| `habits` | The single movement habit and its reminder | `domain/habit_planner.dart`, `application/habit_service.dart` |
| `blocking` | App gate: lock windows, permissions, platform channel | `domain/lock_windows.dart`, `application/app_gate.dart` |
| `notes` | Notes with search | `ui/notes_screen.dart` |
| `finance` | Expenses, budget, category summary | `domain/budget_summary.dart`, `domain/money.dart` |
| `calendar` | Google sign-in, read-only fetch, local cache | `application/calendar_service.dart`, `domain/google_events.dart` |
| `shell`, `more` | Bottom tabs and the More hub | `shell/home_shell.dart`, `shell/shell_tabs.dart` |

`core/` holds what features share: `db` (tables, DAOs, migrations), `notifications`
(gateway, scheduler, actions, setup screen), `check_in` (outcomes and their rules, shared by
routine and deadlines), `home_widget`, `platform`, `time`, `theme` (tokens, pastels,
colours) and `widgets` (the UI kit, including the check-in sheet and Tuck).

## 6. Pure scheduling logic

These functions hold the decisions. They take plain values and return plain values, so
they are cheap to test and safe to reason about.

| Function | File | Decides |
|---|---|---|
| `computeLeaveByPlan` | `routine/domain/morning_plan.dart` | Wake, free time, breakfast, getting ready and leave, laid out backwards from the first class. Keeps the target wake time when it fits, otherwise the latest workable one with `wakeTooLate` set. No class or not fitting are their own results |
| `computeLatePlan` | same | For a late morning: the single next action and an estimated arrival |
| `gradualWakeMinutes`, `wakeOn`, `weekdayWakeOn`, `shiftReachesGoalOn` | `routine/domain/wake_schedule.dart` | Steady wake time, weekend lie-in (0 to 60 min), and the gradual shift: 15 min earlier every 3 calendar days, computed from the calendar only, so a missed night cannot reset it |
| `nightPlan`, `routineTimesOn` | `routine/domain/day_routine_times.dart` | Bedtime = next wake minus sleep target, wind-down = bedtime minus lead |
| `planRoutineReminders` | `routine/domain/routine_reminder_planner.dart` | Wake, eat, leave and wind-down drafts for the next 7 days, skipping past times, "Not today" mutes, and steps low-energy mode drops |
| `computeDeadlineReminders` | `deadlines/domain/deadline_reminders.dart` | 3 days and 1 day before at 19:00, morning of (wake + 30 min), 2 hours before. Drops past, muted, after-due and same-minute nudges |
| `planHabitReminders`, `habitReminderAt` | `habits/domain/habit_planner.dart` | Anchor plus offset per day. Eat and leave fall back to wake on no-class days. None in low-energy mode |
| `lockWindows` | `blocking/domain/lock_windows.dart` | Morning lock (wake to leave, 90 min on no-class days, gone once the routine is done) and wind-down lock (wind-down to wake). Low energy: 30-minute morning, evening from bedtime |
| `routineStatus`, `tomorrowPreview`, `showEveningCard` | `today/domain/today_model.dart` | The Today routine card: no class, doesn't fit, steps, running late, or all done |
| `dayTimeline`, `nowIndex` | `today/domain/day_timeline.dart` | Today's ordered blocks and where the now line sits |
| `suggestOutcome`, `resolvePickedTime`, `checkInNote` | `core/check_in/check_in_rules.dart` | Check-in sheet defaults, wrapping around midnight |
| `focusStateAt`, `focusEndsAt` | `focus/domain/focus_timer.dart` | Running, time-up or ended, from `started_at` and the clock |
| `weeklySummary`, `weeklyTrends` | `review/domain/` | Seven-day counts and four calendar weeks. Counts only grow |
| `budgetSummary`, `describeBudget` | `finance/domain/budget_summary.dart` | Period totals in local time, category totals, neutral wording |
| `parseSchedule`, `overlappingPairs`, `earliestStartByWeekday` | `schedule/domain/schedule_parser.dart` | OCR lines to candidate blocks (grid or line-by-line, MWF/TTh codes, school-hour am/pm guess) |
| `verseFor` | `verse/domain/verse.dart` | Verse by day of year; day 366 wraps |

When you add scheduling behaviour, add it here first as a pure function with tests, then
call it from a service.

## 7. Data layer

Drift (SQLite), local only. The database file lives in the app's data folder on Android
and desktop (`path_provider`), and in IndexedDB through a web worker on the web.

### Conventions

- Every table has `updated_at` (UTC, set by the DAO on every write) and nullable
  `deleted_at` (mixin `SyncColumns`).
- Deletes are soft. DAOs set `deleted_at`, and every read filters it out.
- New tables use a text UUID v4 key from `core/db/uuid.dart` (mixin `UuidKey`). Only
  `settings` (single row, id 1) and `daily_logs` (keyed by date) keep natural keys.
- Times of day are minutes since midnight. Instants are UTC. Money is integer minor units.

### Tables (schema v7)

| Table | Holds |
|---|---|
| `settings` | Single row: wake, sleep, wind-down, breakfast, late threshold, low energy, capture shortcut, weekend leeway, gradual shift, verse, currency, gate switches, unlock minutes, calendar sync time |
| `weekday_schedules` | Per weekday: first class (nullable), commute, prep |
| `tasks` | Deadlines: title, subject, due, status (`pending`, `submitted`, `letGo`), submitted time and note |
| `inbox_items` | Quick captures and whether processed |
| `daily_logs` | Per day: top 3 ids, bed, wake, eat times, routine done |
| `check_ins` | Per day and step: outcome (`onTime`, `later`, `didntHappen`), actual time, reason |
| `focus_sessions` | Task, start, minutes, completed, ended (null = live) |
| `scheduled_notifications` | Every notification handed to Android: unique int id, kind, owner, fire time, title, body |
| `reminder_mutes` | "Not today" for one owner on one day |
| `class_blocks` | Weekday, subject, start, end, room, source (`manual`, `image`) |
| `habits`, `habit_logs` | The movement habit (anchor, offset, active) and done days |
| `blocked_apps` | Package names the gate holds back |
| `notes` | Title, body |
| `expenses`, `budgets` | Spending and the newest budget (weekly or monthly) |
| `calendar_events` | Cached Google events |

### Schema history

| Version | Milestone | Change |
|---|---|---|
| v1 | M1 | `settings` |
| v2 | M3 | The rest of the v1 data model |
| v3 | M7 | `settings.capture_shortcut_enabled` |
| v4 | M8 | `focus_sessions.ended_at` |
| v5 | M9 | Weekend leeway and gradual-shift settings |
| v6 | v2 | Class blocks, habits, blocked apps, notes, finance, calendar; verse, currency, gate and calendar settings; `tasks.submitted_at` |
| v7 | v2.1 | `check_ins`; `tasks.submit_note` |
| v8 | D1 | `settings.onboarded_at` |
| v9 | D2 | `daily_logs.mood`; light day, steady mode and welcome-back settings |
| v10 | D6 | `rewards` |
| v11 | D7 | Dismissed suggestions and school year start settings |

### Adding a migration

Never edit an existing migration step. Migrations use Drift's `stepByStep`, with each
step running against the schema frozen at its version, so an early step never sees a later
column.

1. Change the tables in `core/db/tables.dart` and bump `schemaVersion` in
   `core/db/app_database.dart`.
2. Run `dart run build_runner build`.
3. Dump the new schema: `dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/`.
4. Regenerate the steps: `dart run drift_dev schema steps drift_schemas/ lib/core/db/schema_versions.dart`.
5. Regenerate test schemas: `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/core/db/generated/`.
6. Add the `fromNToN+1` step and a migration test from earlier versions.
7. Add the change to the history list in `app_database.dart`.

## 8. Notifications

### The scheduler

`core/notifications/reminder_scheduler.dart` is the only code that both writes
`scheduled_notifications` and talks to the gateway.

- `replaceOwner(kind, ownerId, drafts)` cancels the owner, drops past drafts, inserts rows
  and schedules them.
- `cancelOwner(kind, ownerId)` cancels in Android and soft-deletes the rows.
- `rebuildAll()` runs on every launch: it drops past rows, cancels everything Android holds,
  and schedules every future row. The table is the source of truth, not the plugin's store.

Features hand over `ReminderDraft`s and never pick notification ids. Ids below 1000 are
reserved for shown (not scheduled) notifications, such as the capture shortcut (id 2).

### Kinds and owners

| Kind | Owner id | Buttons |
|---|---|---|
| `wake`, `eat`, `leave` | Weekday `"1"` to `"7"`; a snooze is `"<n>:snooze"` | Done, 10 more minutes (not on a snooze), Not today |
| `windDown` | Weekday | Going to bed, Not today |
| `deadline` | Task id | Submitted, Not today |
| `habit` | Habit id | Done, Not today |
| `focusEnd` | Session id | Stop here, Keep going |
| `test` | Fixed | None |

Buttons are derived from the kind (`actionsFor`), never stored, so a rebuilt reminder gets
the same buttons. The payload is `kind:ownerId`.

### Responses

Button presses open the app, and each feature's `handle` runs in the main isolate through
`ReminderResponseRouter`. A plain tap on a wind-down, focus or deadline reminder routes to
the matching screen (`routeForResponse`). The exception is the capture shortcut's inline
reply, which runs in the plugin's background isolate (`captureFromNotificationBackground`)
with its own Drift connection, so text is saved without opening the app.

"Not today" writes a `reminder_mutes` row and re-plans that owner. It does not log a miss
or mark anything done.

### Android specifics

- Channels: `pace_reminders` (Reminders) and `pace_capture` (silent, low importance).
- Exact alarms use `SCHEDULE_EXACT_ALARM`, requested from the Reminders screen. If denied,
  the gateway falls back to inexact alarms and the UI says so.
- Reboot rescheduling is the plugin's `ScheduledNotificationBootReceiver`, backed up by
  `rebuildAll()` on launch.
- The notification icon `@drawable/ic_stat_pace` is only named from Dart, so it must stay
  in `android/app/src/main/res/raw/keep.xml`. Release builds shrink resources and will
  otherwise remove it, which crashes startup. Add anything else named only from Dart there
  too.
- Notification behaviour must be verified on a real device, not just an emulator.

## 9. Android native code

`android/app/src/main/kotlin/com/el/pace/`:

| File | Role |
|---|---|
| `MainActivity.kt` | Flutter activity plus the `com.el.pace/gate` method channel |
| `PaceWidgetProvider.kt` | Quick-capture widget (inbox count, Write it down) via `home_widget` |
| `PaceScheduleWidgetProvider.kt` | Today's classes widget. Sets its own alarm for the next block boundary or midnight |
| `ScheduleWidgetModel.kt` | Layout enum and per-widget prefs; `ScheduleDay` picks current and next blocks the same way for every layout |
| `ScheduleWidgetRenderer.kt` | Draws the timeline and strip layouts on a Canvas (RemoteViews cannot size by duration before Android 12) |
| `ScheduleWidgetConfigureActivity.kt` | Layout picker when a widget is placed or reconfigured |
| `ScheduleWidgetClockReceiver.kt` | Re-arms the widget after reboot, update or clock change |
| `GateStore.kt` | Gate config written by Dart: enabled flag, blocked packages, lock windows as instants, unlock-until |
| `GateService.kt` | `specialUse` foreground service. Polls the foreground app every 1.2 s only inside a lock window, otherwise sleeps until the next one |
| `BlockActivity.kt` | The calm block screen. Emergency unlock is always there; Back goes home |
| `GateBootReceiver.kt` | Restarts the gate after reboot or update if it is on |

The routine logic stays in Dart. Dart computes lock windows (`lockWindows`) and writes
them as instants through the channel, and Kotlin only compares the clock against them.

**Permissions** in the manifest: notifications, exact alarms, boot completed, battery
optimisation request, internet (calendar), usage stats, overlay, and foreground service
(special use). The gate uses usage access plus an overlay, never an AccessibilityService,
because Play policy restricts that for non-accessibility use (relevant for M11).

**Release builds** run R8 and resource shrinking. `android/app/proguard-rules.pro` holds the
`-dontwarn` rules for ML Kit's optional language models. Core library desugaring is on for
`java.time`. `compileSdk = 37` with AGP 9.1 and Gradle 9.3.1, needed by the notification
plugins.

## 10. Calendar sync setup

1. Create a Google Cloud project, enable the Google Calendar API and set up the OAuth
   consent screen with the `calendar.readonly` scope.
2. Create a Web OAuth client id and pass it at build time with
   `--dart-define=PACE_GOOGLE_CLIENT_ID=...`. Never commit it.
3. For Android, register the app's SHA-1 in the same project.
4. While the consent screen is in Testing status, grants expire after 7 days, so the owner
   sees "Reconnect" weekly. On the web the access token lasts an hour.

Without a client id, the Calendar screen explains the setup and nothing goes online.
Refresh happens on launch and on resume when the cache is more than an hour old. There is
no background job. Signing out clears `calendar_events`.

## 11. Web and desktop

- The web database needs `web/sqlite3.wasm` and `web/drift_worker.js` to match the locked
  `sqlite3` and `drift` versions. After upgrading either, run `tool/build_web_db.sh` from
  `pace_app/`.
- Without special server headers the web build uses IndexedDB, which is fine.
- The desktop database lives in the per-app data folder (for example
  `~/.local/share/com.el.pace` on Linux).
- Windows and macOS builds have not been verified.

## 12. Testing

`test/` mirrors `lib/`. Run everything with `flutter test`.

- **Domain tests** cover every pure function, including edge cases named in `PLAN.md`
  (impossible mornings, deadlines under two hours away, leap day, week boundaries and
  timezone changes).
- **Widget tests** freeze the clock and override the gateways, for example the late-morning
  card, the tomorrow line, and fitting Today on a 360×640 screen without scrolling.
- **DAO tests** cover CRUD and soft deletes for each table, plus cancel-by-owner.
- **Migration tests** upgrade from every earlier version using the generated schemas in
  `test/core/db/generated/`.
- `test/zz_shots/` is a local screenshot harness and its output is git-ignored. The images
  in `docs/images/` come from it.

Before finishing any change: `dart format .`, `flutter analyze`, `flutter test`.

## 13. Conventions and workflow

- **One milestone at a time.** Plan first, then implement, then commit with a clear message.
- **Ask before adding a dependency.** The v2 additions (image picker, ML Kit, Google
  Sign-In, `http`) were each approved.
- **Copy.** Calm, steady, forgiving. No "late", "failed", "missed" or red. Prefer counts
  that only grow ("days done this week").
- **Low-energy mode** must be handled by every new screen, widget and planner.
- **Tuck** follows `branding/GUIDELINES.md`: never sad or disappointed, and respects
  reduced motion and low-energy mode.
- **New tables** follow the sync-ready conventions in section 7.

## 14. Verification status

From `NOTES.md`, as of 2026-11-19. Tests and builds pass on the development machine, but
most device checks are still open:

| Area | Status |
|---|---|
| M2 notification spike (screen off, swiped away, reboot) | Not yet run on a phone |
| Routine, deadline, habit and focus notifications and their buttons | Not yet verified on a phone |
| Quick-capture widget and shade inline reply | Not yet verified on a phone |
| A2 OCR spike with a real schedule photo | Pending |
| A4 and F3 schedule widget layouts | Not yet checked on a home screen |
| B1 blocking spike (reliability over a full day) | Pending. Do not rely on the gate until it passes |
| Google sign-in | Not tested (no client id on the dev machine) |
| Web and Linux builds | Verified for v1 screens; v2 screens not yet checked on web |

Record results in `NOTES.md` as they come in.

## 15. What comes next

M11 adds accounts and sync (Supabase, PowerSync or push/pull on `updated_at`,
last-write-wins per row), a `user_id` on every table in one migration, JSON export, and the
iOS decision. Until then the schema only stays sync-ready. Anything new goes on the v1.5
list in `PLAN.md` first.
