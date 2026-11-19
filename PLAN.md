# PLAN.md: PACE

*Progress Always Comes Eventually.* Android package ID: `com.el.pace`.

Build in order. Do not start a milestone until the previous one meets its acceptance
criteria. Milestone 2 is the riskiest, so it comes before any feature work.

## Data model (v1)

| Table | Fields |
|---|---|
| settings | target_wake_time, sleep_hours_target, wind_down_lead_minutes, breakfast_minutes, late_threshold_minutes, low_energy_enabled |
| weekday_schedule | weekday, first_class_time (nullable), commute_minutes, prep_minutes |
| tasks | id, title, subject, due_at, status (pending/submitted), source (manual/classroom), created_at |
| inbox_items | id, text, created_at, processed |
| daily_logs | date, top3_task_ids, bed_logged_at, wake_logged_at, eat_done_at, routine_done |
| focus_sessions | id, task_id (nullable), started_at, duration_minutes, completed |
| scheduled_notifications | id, notification_id (the int handed to Android, never reused), kind, owner_id, fire_at, title, body |
| reminder_mutes | id, kind, owner_id, date ("not today" for one reminder owner on one day) |

Every table also carries `updated_at` and nullable `deleted_at` (soft deletes, filtered out of
reads). Ids are text UUID v4 except `settings` (single row, id 1) and `daily_logs` (keyed by
date). Times of day are stored as minutes since midnight, instants as UTC. Schema v1 (M1) holds
only `settings`; M3 adds the rest as a v2 migration. See `CLAUDE.md` rule 9.

---

## M1. Project setup

- Flutter project in `pace_app/` (Dart package `pace`, Android only, package ID `com.el.pace`), folder structure from `CLAUDE.md`
- App display name is "PACE"; show the tagline on the splash or empty Today screen
- Add Riverpod, Drift, theme, basic navigation shell with a placeholder Today screen

**Done when**
- `flutter analyze` and `flutter test` pass
- App launches on a device with an empty Today screen
- No iOS folder or config is added

## M2. Notification spike (do before features)

- Request notification and exact-alarm permissions, with a screen explaining why
- Schedule one exact notification about one minute ahead
- Add a prompt guiding the user to disable battery optimization for the app
- Reschedule after device reboot

**Done when (on a real phone)**
- Notification fires on time with the screen off
- Notification fires after the app is swiped away
- Notification still fires after a reboot
- Result and phone model are noted in the repo (`NOTES.md`)

## M3. Data layer

- Drift tables and DAOs for everything in the data model
- `scheduled_notifications` helper: cancel by owner, reschedule from data
- Migration test

**Done when**
- CRUD tests pass for each table
- Cancel-by-owner removes all pending notifications for that owner

## M4. Leave-by planner

- Pure function `computeLeaveByPlan`: given first class time, commute, prep, breakfast
  minutes and target wake time, return wake, eat (start and end), and leave times and flag
  when the target wake time is too late
- Pure function `computeLatePlan`: given now, first class time, commute and prep, return the
  single next action and an estimated arrival time (used by Today when the morning is late)
- Settings UI: per-weekday first class time, commute, prep; breakfast minutes
- Schedule notifications for wake, eat, leave. Each has a "done" action, a single snooze and
  a "Not today" action that writes a `reminder_mutes` row and reschedules that owner

**Done when**
- Unit tests cover normal day, no class day, impossible schedule, and the late plan
- Changing a weekday's schedule reschedules that weekday's notifications
- "Not today" silences that reminder for the day without marking it done or logging a miss
- Notifications fire on the real device at the computed times

## M5. Deadline tracker

- Add, edit, delete tasks with title, subject, due date and time
- Pure function: reminder times at 3 days before, 1 day before, morning of, 2 hours before,
  skipping any that are already in the past
- Marking submitted cancels remaining reminders
- "Not today" on a deadline reminder (notification action and in-app button) mutes that
  task's reminders for the day only

**Done when**
- Unit tests for reminder times, including deadlines under 2 hours away and muted days
- Marking submitted removes all pending reminders for that task
- Overdue and upcoming tasks are visually distinct without alarming styling

## M6. Today screen (start using the app daily from here)

- Shows next routine step (wake, eat, leave each with a done button), top 3 priorities,
  deadlines due within 48 hours
- Top 3 picker from pending tasks
- Late morning: when now is past the planned wake by more than `late_threshold_minutes`,
  Today shows one card from `computeLatePlan` ("Leave now, arrive 8:05"). No red, no "late"
- Tomorrow preview: one line at the bottom with tomorrow's first class and leave-by time,
  hidden when tomorrow has no class
- Respects low-energy flag from settings (even before M10 UI exists)

**Done when**
- Answers "what do I do right now?" without scrolling on a typical phone
- Late-morning card and tomorrow preview are covered by widget tests with a frozen clock
- Works with no data (clear empty states)

## M7. Quick capture

- Inbox screen: add, process (convert to task or delete)
- Home-screen widget and a notification shortcut that add an inbox item in a couple of taps

**Done when**
- Item saved from widget without opening the full app
- Inbox count shows on Today screen

## M8. "Just start" timer

- Choose a task (or none), start a 10-minute timer, survives screen off
- At the end, choose stop or continue
- Save to `focus_sessions`

**Done when**
- Timer completes with screen off and notifies the user
- Session recorded with correct duration

## M9. Evening check-in and sleep log

- Wind-down notification at (bedtime minus lead time), showing tomorrow's first item
- Check-in flow: review tomorrow, pick top 3, confirm alarm, finish
- "Going to bed" and "I'm up" buttons write to `daily_logs`
- Gradual shift: move target wake time earlier by 15 to 30 minutes every few days
  until the goal is reached (pure function plus tests)
- Weekend wake time stays within about an hour of weekday time

**Done when**
- Bedtime is derived from wake time and sleep target
- Unit tests for the gradual shift, including reaching the goal and not overshooting
- Missing a night does not reset the schedule

## M10. Low-energy mode and weekly view

- Settings toggle (also reachable from Today). When on, show only wake, leave, and
  deadlines due within 48 hours
- Weekly view: count of days with routine done, average actual wake time, simple list
  of sleep log entries. No streak reset, no red indicators

**Done when**
- Toggling low-energy mode changes Today and reminder behavior consistently
- Weekly view reads correctly with partial or empty data

---

## After v1

Use v1 for at least two weeks before adding anything, and finish the M2 real-device check
(`NOTES.md`) before starting v2.

v1.5 candidates, in rough order: deadline buffer (a personal due date a day before the real
one), gentle rescue after a missed morning (switch to the low-energy list for that day),
first-step hints on the focus timer, one-tap evening energy check-in shown on the weekly view,
subject colours and a class list, Google Classroom import (optional, never required).

---

## v2

v2 is split into three phases. Each phase is usable on its own, so stop after any phase if
needed. Keep low-energy mode working on every new screen and widget. Android-only features
(OCR, blocking, widgets) go through `core/platform/platform_features.dart` and are hidden on
web and desktop.

### New tables (v2)

Every new table follows `CLAUDE.md` rule 9: text UUID v4 `id`, `updated_at`, nullable
`deleted_at`, soft deletes. Times of day are minutes since midnight, instants UTC. The
database is at schema v5, so v2 migrations start at v6, one step per milestone.

| Table | Fields |
|---|---|
| class_blocks | id, weekday, subject, start_time, end_time, room (nullable), source (manual/image) |
| habits | id, name, anchor (wake/eat/leave/wind_down), offset_minutes, active |
| habit_logs | id, habit_id, date, done |
| blocked_apps | id, package_name (unique), label |
| notes | id, title, body, created_at |
| expenses | id, amount_minor (integer, minor units), category, note, spent_at |
| budgets | id, period (weekly/monthly), amount_minor |
| calendar_events | id, external_id, title, start_at, end_at, all_day, cached_at |

Settings gains `verse_enabled`, `currency_code`, the gate's `gate_enabled`,
`morning_lock_enabled`, `wind_down_lock_enabled` and `unlock_minutes`, and
`calendar_synced_at`; `tasks` gains `submitted_at` for the weekly counts. Verses are not a table: they ship as a
read-only bundled asset (`assets/verses.json`).

### Phase A: routine support

**A1. Daily Bible verse**
- Bundle 365 verses from a public-domain translation (WEB or KJV) as `assets/verses.json`
- Pick by day of year (pure function), show on Today screen, optional line in wake-up notification
- Setting to hide the verse

Done when
- Verse shows with airplane mode on and changes the next day
- Verse can be turned off, and low-energy mode hides it
- Leap-year day 366 falls back to a valid verse

**A2. Schedule OCR spike (Android only)**
- Add image picker and on-device text recognition (ML Kit, **bundled model** so nothing is
  downloaded through Play Services), no network
- Test with the owner's real schedule image and print recognized text with positions
- Gate the import entry point in `platform_features.dart`; manual block entry works everywhere

Done when
- A short note in `NOTES.md` records whether OCR output is good enough to parse
- If not, the decision to rely on manual block entry is written down and A3 skips OCR

**A3. Review screen and save to schedule**
- Pure Dart parser: recognized text lines to candidate class blocks (subject, day, times)
- Review screen: every block is editable, deletable, and addable manually
- Nothing is saved until the user confirms
- Confirmed blocks fill `class_blocks`. For each affected weekday the review screen shows the
  earliest block's time next to the current `first_class_time` and the user chooses which to
  keep (never overwritten silently). Then reminders are rescheduled

Done when
- Parser unit tests cover clean input, missing times, and overlapping blocks
- Confirming blocks reschedules leave-by notifications for the affected weekdays
- Re-importing replaces earlier image-sourced blocks and keeps manual ones

**A4. Time-block widget (Android only)**
- Second home-screen widget, next to the quick-capture one, showing today's class blocks with
  the current block highlighted
- Android refreshes widgets on its own only every 30 minutes or more, so updates at block
  boundaries and at midnight use scheduled alarms. Handles no-class days

Done when
- Widget shows the correct blocks for today and highlights the current one on a real phone
- Widget survives a reboot and updates without opening the app

**A5. Movement habit**
- One habit (default: 10 minutes of movement) with a reminder tied to a chosen routine point
  (anchor plus offset, computed by a pure function from that day's plan)
- Reminder goes through `scheduled_notifications` with the habit as owner
- One tap marks done. Done days feed the weekly view as positive counts only

Done when
- Reminder fires on a real device and a done tap cancels the remaining reminder
- Changing the routine reschedules the habit reminder
- Missing a day shows no failure state and does not reset anything

### Phase B: control and insight

**B1. Blocking spike (Android only)**
- Use usage access (foreground app detection) plus an overlay, with a clear explanation screen.
  Do not use an AccessibilityService: Play policy restricts it for non-accessibility use,
  which matters for M11
- Show a block screen for one chosen test app
- Test on the owner's phone brand with battery optimization on and the screen locked for a while

Done when
- The test app is blocked reliably and the service survives for a full day
- Result and phone model are recorded in `NOTES.md`. If it is unreliable, stop and decide before B2

**B2. Blocking gate**
- Choose apps to block. Lock until the morning routine is marked done, and during the wind-down window
- Emergency unlock for a configurable number of minutes, always available from the block screen
- Master off switch in settings, and low-energy mode loosens the gate (shorter lock window)

Done when
- Completing the morning routine unlocks blocked apps immediately
- Wind-down lock starts and ends at the right times
- Emergency unlock works every time and is never hidden
- Turning the gate off removes all blocking

**B3. Analytics (extends the weekly view)**
- Built on the M10 weekly view, not a separate dashboard: planned vs. actual wake time,
  average sleep hours, deadlines submitted (a count, not an on-time rate), focus sessions
  per week, movement habit days
- Pure Dart aggregation functions with unit tests
- Neutral presentation: trends and averages, no red or failure indicators

Done when
- Every view renders correctly with no data, partial data, and a full month of data
- Aggregation tests cover week boundaries and timezone changes

### Phase C: new modules

Each module gets its own feature folder and tables and does not import routine code.

**C1. Notes**
- Create, edit, delete, and search notes. Separate from the quick-capture inbox
- Option to turn an inbox item into a note

Done when
- Search finds text in titles and bodies
- Deleting asks for confirmation and no data is lost on app restart

**C2. Finance**
- Log an expense with amount, category, and note in a few taps
- Amounts stored as integer minor units, with one currency setting
- Set a weekly or monthly budget, see spent vs. remaining and a simple category summary
- Neutral wording when over budget, no alarming styling

Done when
- Totals are correct across period boundaries
- Budget summary works with no budget set and with no expenses

**C3. Google Calendar sync (read-only, last, optional)**
- Google sign-in with read-only calendar scope, requires a Google Cloud project and OAuth consent screen
- While the OAuth app is in "Testing" status, refresh tokens expire after 7 days, so the owner
  signs in again weekly until the app is published (`calendar.readonly` is a sensitive scope
  and needs Google verification to publish)
- Release builds need the INTERNET permission. Android and web only; hidden on desktop
- Fetch events and cache them in `calendar_events`, show them next to class blocks on Today and the widget
- Manual refresh plus background refresh when online

Done when
- Events appear next to class blocks and still show offline from the cache
- Expired sign-in shows a calm "reconnect" prompt, never an error state
- Signing out clears cached events
- The app works fully with sync never set up

---

## v2.1 fixes (from owner testing, 2026-11-19)

**F1. Class room not saved (bug)**
- The class sheet's Save returned the form as of the last rebuild; typing a room never
  rebuilt it, so a room typed last (or a room-only edit) was dropped. Fixed in the sheet,
  shared by add, edit and import review.

**F2. Check-in sheet for routine steps and deadlines**
- Tapping a routine step (wake, eat, leave, wind-down) opens a quick sheet: done on time,
  done a bit later (pick the actual time), or didn't happen today, plus an optional short reason
- Deadlines get the same sheet: submitted, submitted late (pick time), or couldn't submit (let go)
- Done steps can be tapped again to change or clear the check-in
- Review and Trends show neutral counts ("1 a bit later"), never misses or red
- Notification buttons stay one tap (on time, now)

Done when
- Every outcome is stored and survives a restart; wake averages use the picked time
- "Didn't happen" quiets that step's reminders for the rest of the day
- Low-energy mode keeps the sheet short (note collapsed)

**F3. Schedule widget layouts (Android)**
- Each schedule widget picks its layout when placed, and can be reconfigured:
  list (current), time-block timeline, now & next, day progress strip
- All layouts follow low-energy mode, dark mode, and the block-boundary alarms

Done when
- All four layouts are correct on a real phone, survive a reboot, and update without opening the app

---

## M11. Accounts and sync (the SaaS version, after v2)

Drift stays the source of truth on the device. Supabase (Postgres, auth, row-level security)
is the backend. Sync through PowerSync or a hand-rolled push/pull on `updated_at` with
last-write-wins per row. Adds `user_id` to every table in one migration. Notifications stay
locally scheduled; push is a backup only. iOS support is decided here. Export/backup to JSON,
and shared "routine done" visibility for a coach or parent, come after sync works.

Still not planned: workouts (beyond the single movement habit), consequence systems, streaks.
Anything new is added to the v1.5 list first and only moves into a phase on purpose.
