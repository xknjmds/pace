# Verification report: PACE pitch

*Skill: startup-pitch | Generated: 2026-11-19*

Run inline (no subagent) against every deliverable in `pitch/`.

## Summary
**0 Critical · 3 Warnings · 3 Info.** OK to proceed. Fix the warnings before the event.

## Universal checks
| Check | Result |
|---|---|
| Unlabelled claims | Pass. Market figures are tagged Data/Estimate on slide 10 and in the appendix; the paid tier is marked Assumption on slide 11 |
| Internal contradictions | Pass. Times 06:30 / 06:50 / 07:35 are the same in the deck, scripts and intake, and match `computeLeaveByPlan` for 08:00 class, 25 min commute, 30 min prep, 15 min breakfast |
| Confidence consistency | Pass. Secondary sources (StatCounter via Backlinko, Tiimo via Wikipedia) are labelled secondary in `raw/` |
| Data gaps declared | Pass. No users, real-device reminder check pending, high-school students not counted |
| Flags present | Pass. Every deliverable ends with Red flags, Yellow flags and Sources |
| Stale data | Info. StatCounter figure is Nov 2025; Tiimo pricing conflicts across sources (pricing deliberately not quoted) |
| Duplicate-source corroboration | Info. Backlinko and Search Engine Land both re-quote StatCounter; counted as one source |

## Pitch-specific checks
| Check | Result |
|---|---|
| Claims vs source data | Pass. 335 tests / 59 files / ~18.6k lines / 13 modules counted from the repo on 2026-11-19. UI copy on slides 5–7 copied from `now_card.dart`, `today_model.dart`, the focus and review screens |
| Cross-format consistency | Pass. 1-min, 2-min, 5-min, full, email and outline use the same numbers and wording |
| Pitch vs appendix | Pass. Appendix answers every weakness the deck admits (users, reminders, revenue) |
| Traction without timeframe | n/a. No traction is claimed |
| Top-down TAM | Pass. Bottom-up funnel with stated assumptions |
| Titles without accomplishments | Warning. Team slide is placeholders; the template asks for "what they built", not titles |

## Warnings
1. **Comparison table (slide 9) is our reading, not verified per app.** Re-check Tiimo, Structured, Habitica and Todoist features (especially offline/account requirements) before the event.
2. **"~75% procrastinators" is self-report.** Fine to use; say "call themselves".
3. **Team placeholders.** Fill the `TEAM` block in `deck.html` and re-run `python3 pitch/tool/build_notes.py`.

## Excluded on purpose
- "80–95% of students procrastinate" (traces to a 1977 self-help book).
- "55% of students burned out" (aggregator, no primary source).
- "63% more likely to quit after a broken streak" (untraceable).

## Visual checks (deck matches the app)
- All 13 slides screenshotted at 1600×900 in light and dark, at 390×844 and 1280×1000, and with reduced motion forced. No overflow, Tuck never cropped, placeholders visible.
- better-ui detection grep: no `transition: all`, no `will-change`, the only `:hover` is inside `@media (hover: hover)`, press scale is 0.96, overlay scroll has `overscroll-behavior: contain`, no hard-coded icon fills, and theme switching suppresses transitions.
- Not verified: an on-screen side-by-side with the running app (the app wasn't launched); the token values were compared against the theme source files instead.
