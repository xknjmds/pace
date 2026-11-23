# Q&A preparation: PACE

*Skill: startup-pitch | Generated: 2026-11-19*

## Top 10 likely questions

**1. "Isn't this just Todoist, Google Calendar, or an alarm clock?"**
Those store *what* and *when it's due*; an alarm rings at a time you chose. PACE **computes** the times from one input (class time), resets them for each weekday, and **rebuilds the plan when you're late**, with one next step instead of a list. That last part is the bit nobody else does.

**2. "Tiimo already exists and won App of the Year. Why you?"**
Tiimo proves people want calm planners (500k+ users). But Tiimo is a canvas you fill in yourself; PACE fills in the morning for you. It's also Android-first and works fully offline without an account. We see Tiimo as proof of demand, not a reason to stop.

**3. "How many users do you have?"**
None beyond our team yet. We focused on getting it built and tested properly: 335 automated tests. The next step is a pilot with classmates at [Our school], measuring [mornings on time / days routine done] over [N] weeks.

**4. "How will you make money?"**
Today we don't, and we don't have to; it runs on the phone with no server costs. The plan after the pilot: the core planner stays free, and optional accounts/sync/backup could be a paid tier (Tiimo's model: about 10% of users pay). That's an assumption we still have to test.

**5. "Why no streaks? Streaks work for Duolingo."**
They motivate people who are already doing well. For someone who is tired or burned out, a streak back at zero reads as failure. Research from the University of Delaware found that highlighting a broken streak makes people less likely to keep going, especially when they blame themselves. We count "days done this week" instead, which only goes up.

**6. "How do you know the times are right?"**
The planner is a pure function (`computeLeaveByPlan`) with unit tests for a normal day, a no-class day, an impossible schedule, and running late. Same inputs, same outputs, every time.

**7. "Do reminders actually fire on time? Android kills background apps."**
That's the hardest engineering part. We use Android's exact-alarm permission, guide the user to turn off battery optimisation, and reschedule after reboot. **Honestly:** the real-phone check is still in progress (we document it in `NOTES.md`). We'll only claim it's reliable once that's done.

**8. "What about privacy?"**
No account, no server, no analytics. Everything is stored on the phone in a local database. The only optional network feature is read-only Google Calendar sync, which is off by default.

**9. "What about iPhone users?"**
Android first because it's about 73% of phones worldwide and it's what we use. The app also runs on web and desktop (without reminders). iOS is a decision for after accounts and sync.

**10. "What would you do with prize money / mentoring?"**
[Adjust to the competition] Real-device testing across phone brands (battery behaviour differs a lot), a proper pilot, and Play Store publishing costs.

## Objection handling
| Objection | Answer |
|---|---|
| "It's too niche: just mornings." | Mornings are the anchor: one late morning ruins the day. PACE also covers deadlines, focus, evening wind-down, and v2 adds timetable import, habits, notes and money. |
| "Students won't set it up." | Setup is four numbers per weekday, and v2 can read a timetable from a photo (you review it before saving). |
| "Gentle apps get ignored." | Gentle isn't silent. Deadlines get four reminders that step up; the leave reminder rings at the computed time. It's *kind*, not *quiet*. |
| "A big company could copy this." | Possibly. Our edge is focus: built by the user it's for, with a strict no-guilt design that big productivity apps (built around streaks and karma) don't follow. |

## Known weaknesses (say these before they're found)
- **No users yet.** Mitigation: pilot plan with a clear metric.
- **Reminders unverified on a real phone.** Mitigation: test across brands before any reliability claim.
- **One-person origin story.** Mitigation: the pilot tests whether others share it; the procrastination data suggests they do.
- **No proven revenue.** Mitigation: zero running costs today; the freemium path is modelled on a working comparable.

## Backup numbers
| Figure | Value | Source | Tag |
|---|---|---|---|
| Higher-ed students, 2024 | 269M | UNESCO | Data |
| Android share, Nov 2025 | 72.77% | StatCounter (secondary) | Data |
| Android higher-ed students | ~196M | 269M × 72.8% | Estimate |
| Self-identified procrastinators | ~75% | Steel & Ferrari 2013 | Data |
| …of the above | ~147M | 196M × 75% | Estimate |
| Tiimo users / paid | 500k+ / ~50k | Wikipedia-based | Data (secondary) |
| Automated tests | 335 in 59 files | repo count | Data |
| Dart lines (non-generated) | ~18.6k | repo count | Data |

## Red flags
- Don't quote "80–95% of students procrastinate": it traces to a 1977 self-help book.
- Don't quote untraceable streak statistics ("63% more likely to quit").

## Yellow flags
- Burnout prevalence figures vary widely; we deliberately don't put one on a slide. If asked, Chegg's 2023 global survey reported 46% academic exhaustion among 18–21-year-olds (check the full report before quoting).

## Sources
See `pitch-full.md` › Sources, plus https://databoks.katadata.co.id/en/consumer-services/statistics/6875b3310e4e5/global-mental-health-challenges-faced-by-students-in-2024 (Chegg snippet).
