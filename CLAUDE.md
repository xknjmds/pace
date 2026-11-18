# CLAUDE.md

**App name:** PACE (Progress Always Comes Eventually)
**Android package ID:** `com.el.pace`
**Tone:** calm, steady, forgiving. Copy and UI should never shame or rush the user.
**Mascot:** Tuck the turtle is the brand (`branding/GUIDELINES.md`). Tuck is never sad or
disappointed, and respects reduced motion and low-energy mode.

Personal routine and productivity app. Single user, Android first, offline-first.
Read `PLAN.md` for milestones and acceptance criteria. Work on one milestone at a time.
v1 (M1 to M10) is built. Current work is v2 (phases A, B, C in `PLAN.md`), then M11.

## Purpose

The owner has no daily system: inconsistent wake and sleep times, late to school,
skipped breakfast, forgotten submissions, procrastination, and is recovering from burnout.
The app is an external memory and a nudge, not a to-do list. Every feature must answer:
"does this help the owner start the right thing at the right time?"

## Stack

- Flutter + Dart. **Android is the primary target.** Web and desktop (Linux, Windows, macOS)
  also run, with everything except reminders, notification buttons and the home-screen
  widget (owner's decision, 2026-11-18). Platform differences go through
  `core/platform/platform_features.dart` and the no-op gateway and widget bridge, never
  scattered `Platform` checks. Do not add iOS code or config.
- Web database: `web/sqlite3.wasm` and `web/drift_worker.js` must match the locked
  `sqlite3` and `drift` versions; regenerate with `tool/build_web_db.sh` after upgrading.
- State: Riverpod
- Database: Drift (SQLite), local only, no backend, no accounts
- Notifications: `flutter_local_notifications` + `timezone` + `flutter_timezone`
- Home widget: `home_widget`
- Permissions: `permission_handler`
- Verify current package docs and Android exact-alarm rules before implementing notifications
- v2 additions (ask before adding each): image picker + ML Kit text recognition (bundled
  model) for schedule OCR, an Android usage-access + overlay approach for app blocking
  (no AccessibilityService), Google Sign-In + Calendar API (read-only) for calendar sync.
  Android-only ones are gated in `platform_features.dart`

## Structure

The Flutter project lives in `pace_app/`; paths below are relative to it.

```
lib/
  core/        db, notifications, time utils, theme
  features/
    routine/   leave-by planner, wake anchor, sleep log
    deadlines/ tasks, reminder rules
    today/     Today screen
    inbox/     quick capture
    focus/     "just start" timer
    review/    evening check-in, weekly view, analytics (B3)
    verse/     daily Bible verse (bundled asset)
    schedule/  class blocks, image import, time-block widget
    habits/    movement habit
    blocking/  app blocking gate
    notes/     notes
    finance/   expenses and budget
    calendar/  Google Calendar read-only sync
  main.dart
test/          mirrors lib/
```

## Rules

1. **Scheduling logic is pure Dart.** Functions like `computeLeaveByPlan` and
   `computeReminderTimes` take plain inputs and return plain outputs. No Flutter,
   Drift, or plugin imports. Always unit test them.
2. **Notifications are rebuilt from data.** Store every scheduled notification in the
   `scheduled_notifications` table with an owner id. To change reminders, cancel by owner
   and reschedule. Never hand-manage notification ids elsewhere.
3. **Offline-first.** No network calls, with one exception: Google Calendar sync (C3),
   which is optional, read-only, cached locally, and must never be required for the app
   to work.
4. **Fast to use.** Opening the app to marking something done must take a few taps.
   Today screen answers "what do I do right now?" immediately.
5. **Forgiving by design.** No punishment, no red failure states, no streaks that reset
   to zero. Use positive counts such as "days done this week."
6. **Low-energy mode** must be respected by every screen and widget that lists items,
   including all v2 features. The blocking gate must loosen in low-energy mode.
7. Keep widgets small and feature-local. Shared UI goes in `core/`.
8. Use Drift migrations for every schema change. Never edit an existing migration.
9. **Sync-ready schema.** Every table has `updated_at` (UTC, bumped by the DAO on every write)
   and nullable `deleted_at`. Deletes are soft: DAOs set `deleted_at` and every read filters
   it out. New tables use a text UUID v4 primary key from `core/db/uuid.dart` (`settings` and
   `daily_logs` keep their natural keys). No `user_id` until M11.
10. **OCR is never trusted.** Imported schedule blocks are saved only after the user
    reviews and confirms them.
11. **Blocking must always be escapable.** The emergency unlock is always reachable and
    there is a master off switch. Never trap the user.
12. **Analytics and finance are neutral.** Show trends and totals, not shame. No red
    failure indicators.
13. Finance, notes, and calendar are independent modules: no imports from routine code.

## v1 scope (built)

Must: leave-by planner, deadline tracker with escalating reminders, Today screen,
quick capture (inbox + widget), "just start" timer.
Should: evening check-in with wind-down and sleep log, low-energy mode, weekly view.

## v2 scope (current)

Phase A: daily Bible verse, schedule image import (OCR + review), time-block widget,
movement habit.
Phase B: app blocking gate, analytics (extends the weekly view).
Phase C: notes, finance, Google Calendar sync (read-only).
Build phases in order. Do the OCR spike (A2) and blocking spike (B1) before the
features that depend on them, and stop to report if a spike fails.

## Non-goals (do not build)

Punishment or demerit system, iOS, full workout system (only the single movement habit
is planned), social features, and anything not listed in `PLAN.md`. Google Classroom import
is optional and must never be required for the app to work.
Cloud sync and accounts come after v2 (M11, the SaaS version); until then the schema only
stays sync-ready, see rule 9.

## Workflow

- Plan first, then implement. Keep each change to one milestone.
- Before finishing a task: `dart format .`, `flutter analyze`, `flutter test`.
- Commit after each completed milestone with a clear message.
- Release builds shrink resources: anything named only from Dart (like the notification
  icon) must be listed in `android/app/src/main/res/raw/keep.xml`.
- Notification behavior must be verified on a real device, not just the emulator.
  If it cannot be verified, say so explicitly instead of claiming it works.
- Ask before adding any new dependency.
