# Intake: PACE

*Skill: startup-pitch | Generated: 2026-11-19*

## Audience
School / student startup competition judges. No money ask. The goal is to make judges understand the problem, believe the insight, and see a working product.

## The 2-sentence description
PACE is a calm Android app that tells a student what to do right now: when to wake up, when to eat, when to leave, and which deadline to start. It plans the morning backwards from the first class and nudges gently, without streaks or guilt.

**Example:** First class is at 08:00 and the commute is 25 minutes. PACE works backwards and sets wake at 06:30, breakfast at 06:50 and leave at 07:35. If the student wakes up late, Today shows one card ("One thing now") with the single next step, instead of a red list of everything they missed.

## Problem
The founder's own starting point (from `CLAUDE.md`): no daily system, wake and sleep times all over the place, late to school, skipped breakfast, forgotten submissions, procrastination, recovering from burnout.
- To-do apps store tasks, but they don't say *when* to start them.
- Habit apps use streaks that reset to zero, so one bad day reads as failure. That pushes tired people to give up.

## Insight
People who are behind don't need more lists. They need **one nudge at the right moment, and forgiveness when they miss it**. The time to start almost everything in a student's morning can be calculated from one fact, the first class time, so the app can do the planning for them.

## Solution (what's built, verified in code)
- **Leave-by planner:** a pure function `computeLeaveByPlan` takes class time, commute, prep and breakfast and returns wake/eat/leave times. `computeLatePlan` gives a single next action when the morning runs late.
- **Today screen:** the "Right now" card with step tiles and a three-stone cairn that fills as steps are done, top 3, deadlines due within 48 h, tomorrow preview.
- **Deadline tracker:** reminders 3 days, 1 day, morning of, and 2 hours before. "Not today" mutes a task for the day without counting it as a miss.
- **Quick capture:** inbox, home-screen widget, notification shortcut.
- **"Just start" timer:** 10 minutes, "Keep going, 10 more".
- **Evening check-in,** sleep log, **low-energy mode** (shows only what is close), weekly view with positive counts.
- **v2 (committed):** daily verse, schedule import from a photo (OCR + review), time-block widget, movement habit, app-blocking gate with an always-available emergency unlock, analytics, notes, money, Google Calendar read-only.
- Offline-first, no account, data stays on the phone. Android first. Web and desktop also run (without reminders).
- About 18,600 lines of Dart (not counting generated code), 59 test files, 335 tests.

## Traction
No users yet beyond the founder. Real-device notification check is still pending (`NOTES.md`). The deck must say this honestly.

## Business model
None today. Possible path after v2: M11 accounts + sync (Supabase), then optional paid sync/backup. Marked [Assumption].

## Team
`[Team name]`, `[Member names]`: placeholders. The user fills these in through the `TEAM` object in `deck.html`.

## Formats
All of them: deck (HTML), presenter notes (PDF), full/5/2/1-min scripts, judges' note, Q&A appendix, outline, scorecard.
