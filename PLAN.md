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
| scheduled_notifications | id, kind, owner_id, fire_at |
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

Use v1 for at least two weeks before adding anything.

v1.5 candidates, in rough order: deadline buffer (a personal due date a day before the real
one), gentle rescue after a missed morning (switch to the low-energy list for that day),
first-step hints on the focus timer, one-tap evening energy check-in shown on the weekly view,
subject colours and a class list, daily Bible verse (bundled offline JSON, public-domain
translation), Google Classroom import.

## M11. Accounts and sync (the SaaS version)

Drift stays the source of truth on the device. Supabase (Postgres, auth, row-level security)
is the backend. Sync through PowerSync or a hand-rolled push/pull on `updated_at` with
last-write-wins per row. Adds `user_id` to every table in one migration. Notifications stay
locally scheduled; push is a backup only. iOS support is decided here. Export/backup to JSON,
and shared "routine done" visibility for a coach or parent, come after sync works.

Still not planned: app blocking, workouts, analytics dashboards, consequence systems, streaks.
