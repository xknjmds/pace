# Q&A preparation: PACE

*Skill: startup-pitch | Generated: 2026-11-19 (rebuilt to follow the Topic 08 guide)*

## Top 12 likely questions

**1. "How many users do you have?"**
None beyond our team yet. We spent our time building and testing it properly (335 automated tests). The next step is exactly what we're asking for: a week-1 survey of our 30 classmates for a baseline, a week-2 set-up test, then the 8-week pilot in our classroom.

**2. "Where does the ₱4,500 go?"**
| Item | Amount | Why |
|---|---|---|
| Thank-you load, 30 classmates × ₱50 | ₱1,500 | Small thanks for 8 weeks of surveys and a short time diary |
| Onboarding session + printed surveys | ₱1,000 | One set-up session in class; paper surveys for the baseline |
| Google Play developer account (US$25, one-time, ~₱64/US$) | ₱1,600 | Needed to distribute through Play's testing tracks |
| Buffer, about 10% | ₱400 | Price changes |
| **Total** | **₱4,500** | All estimates. No devices: we test on our own and our classmates' phones, which already cover several brands |

**3. "Why ₱49? Would students actually pay?"**
We don't know yet, and we say so. ₱49 is under the price of a meal and close to a weekly load. The business proof tests it directly: in week 4–8 we offer Plus as a pre-order and count how many say yes. If it's near zero, we change the offer before building accounts.

**4. "Isn't your ROI made up?"**
It's a model, and the slide says so. The inputs: 5 minutes saved per school day (an assumption we'll measure with a time diary), 22 school days, and ₱94/hour (Metro Manila minimum wage ₱755/day ÷ 8). We left out grades and stress because we can't measure or attribute them. The useful number is the break-even: **1.4 minutes a day**. Even if our 5-minute guess is very wrong, the price is easy to justify.

*Honest caveat if pushed:* most of the time saving comes from the free planner; Plus is priced for convenience (sync and backup). The ROI shows the price is small next to the value; whether students pay is what the business proof tests.

**5. "Isn't this just Google Calendar, an alarm, or Todoist?"**
Those store *what* and *when it's due*; an alarm rings at a time you guessed. PACE **works out** wake, eat and leave times from your class time, resets them for each weekday, and **rebuilds the plan when you're late**, with one next step instead of a list.

**6. "Tiimo already exists and won App of the Year."**
Good: it proves students want calm planners (500,000+ users). But Tiimo is a canvas you fill in; PACE fills in the morning for you, is Android-first, and works offline without an account.

**7. "Why no streaks? Streaks work for Duolingo."**
They motivate people already doing well. For someone tired or burned out, a streak back at zero reads as failure. University of Delaware research (INSEAD summary) found that highlighting a broken streak makes people less likely to continue, especially when they blame themselves. We count "days done this week", which only goes up.

**8. "How will you know the pilot worked?"**
We decide the bar before we start: at least 50% still using PACE in week 8; fewer self-reported late days a week than the week-1 baseline; and at least 10% pre-ordering Plus (Tiimo's paid share is about 10%). Each result reports sample size, period, baseline and metric definition, as the guide asks. *[These thresholds are our proposal: adjust as a team before the pitch.]*

**9. "Do reminders actually fire on time? Android kills background apps."**
That's the hardest engineering part. We use Android's exact-alarm permission, guide users to turn off battery optimisation, and reschedule after reboot. The real-phone check is still in progress. Our 30 classmates' phones cover several brands, which is exactly the spread we need to test on.

**10. "What about privacy?"**
No account, no server, no analytics. Everything is stored on the phone. The only optional network feature is read-only Google Calendar sync, which needs you to sign in. Plus's sync will be opt-in.

**11. "Why only Android?"**
About 73% of phones worldwide run Android, and it's what our classmates use. The app also runs on web and desktop (without reminders). iOS comes after accounts and sync.

**12. "What if you don't get the money?"**
We run the pilot anyway: we'd pay the Play Store fee ourselves and skip the thank-you load. Fewer classmates may keep answering until week 8, but it's still evidence.

**13. "Isn't one classroom too small and too friendly?"**
Yes: 30 people who know us is a first signal, not a representative sample, and we'll say so when we report. It's the cheapest way to find what breaks. If the results hold, the next step is a second class we don't know.

## Objection handling
| Objection | Answer |
|---|---|
| "Too niche: just mornings." | Mornings are the anchor; one late morning ruins the day. PACE also covers deadlines, focus, the evening check-in, timetable import, habits, notes and money. |
| "Students won't set it up." | Set-up is four numbers per weekday, and a timetable can be read from a photo (you review it before saving). The week-2 use test measures exactly this. |
| "Gentle apps get ignored." | Gentle isn't silent: the leave reminder rings at the computed time and deadlines get four reminders that step up. Kind, not quiet. |
| "A big company could copy this." | Possibly. Our edge is focus: built by the users it's for, with a strict no-guilt design that big productivity apps (built on streaks and karma) don't follow. |

## Known weaknesses (say them before they're found)
- **No customer evidence yet.** Mitigation: the three-test validation plan with set metrics.
- **Reminders unverified on real phones.** Mitigation: test across our classmates' phones (several brands).
- **Pilot is one classroom (30).** Mitigation: report it as a first signal; a second, unfamiliar class next.
- **Price untested; Plus not built yet** (needs accounts). Mitigation: pre-order test before building.
- **ROI inputs are assumptions.** Mitigation: break-even framing + time diary in the pilot.

## Backup numbers
| Figure | Value | Source | Tag |
|---|---|---|---|
| Higher-ed students, 2024 | 269M | UNESCO | Data |
| Android share, Nov 2025 | 72.77% | StatCounter (secondary) | Data |
| Self-identified procrastinators | ~75% | Steel & Ferrari 2013 | Data |
| Android higher-ed procrastinators | ~147M | 269M × 72.8% × 75% | Estimate |
| Tiimo users / paid | 500k+ / ~50k | Wikipedia-based | Data (secondary) |
| NCR minimum wage | ₱755/day → ₱94/h | SunStar, Emerhub (2026) | Data (verify wage order) |
| USD/PHP | ~64 | exchange-rates.org, Nov 15, 2026 | Data |
| Play developer fee | US$25 one-time | Google support | Data |
| Plus price | ₱49/month, ₱399/year | ours | Assumption |
| Minutes saved per school day | 5 | ours | Assumption |
| Break-even | 1.4 min/day | ₱49 ÷ ₱94/h ÷ 22 days | Calculated |
| Automated tests | 335 in 59 files | repo count | Data |

## Red flags
- Don't quote "80–95% of students procrastinate" (traces to a 1977 self-help book) or untraceable streak statistics.
- Don't call the ROI a result.

## Yellow flags
- Pilot success thresholds (Q8) are a proposal: agree on them as a team.

## Sources
See `pitch-5min.md` › Sources.
