# Deck outline: PACE

*Skill: startup-pitch | Generated: 2026-11-19*

Built as `deck.html`. The headlines alone tell the story:

| # | Headline | Body | Visual | Tuck |
|---|---|---|---|---|
| 1 | PACE: Progress Always Comes Eventually | A calm Android app that tells a student what to do right now. Team name, event, members | Wordmark (Moss) + large Tuck | idle (waving) |
| 2 | PACE tells you what to do right now. | 4 inputs → Up 06:30 · Eat 06:50 · Leave 07:35 · Class 08:00. Reminder with Done / snooze / Not today | Input card → arrow → pastel time tiles | morning |
| 3 | The day falls apart before school even starts. | Sleep times all over · late, breakfast skipped · submissions too late · burnout. ~75% self-identified procrastinators | 4 kit cards with pastel chips, stat chip | leaving |
| 4 | Tired people don't need more lists. They need one nudge, and forgiveness. | Most apps: store tasks, reset streaks, show misses. PACE: works out when to start, counts what got done, one next step | Two grouped lists (neutral vs pastel) + research footnote | note |
| 5 | Open the app, see the one next thing. | Tap a step, the cairn fills · top 3 picked the night before · late: "Leave now. You arrive about 08:05." | HTML phone mock-up of the real Today screen + late card | (phone) |
| 6 | Deadlines nudge early. Then PACE helps you start. | 3 days / 1 day / morning of / 2 h before · Not today · Submitted · quick capture · 10-min timer | Reminder ladder + focus ring mock | focus |
| 7 | Missing a day is normal. PACE never punishes it. | Low-energy mode · counts not streaks · no red · evening check-in · never trapped · Tuck never sad | 6 kit cards | resting |
| 8 | It's built and tested, not a mock-up. | 335 tests · 18.6k lines · 13 modules · 0 accounts. v1/v2 module chips. Honest status line | Stat tiles + pastel module chips | proud |
| 9 | Other apps help you plan. PACE does the planning. | PACE vs Tiimo, Structured, Habitica, Todoist on 4 criteria. Tiimo's success = demand | Comparison table, PACE row in mint | idle (small) |
| 10 | Millions of students start the day already behind. | 269M → ~196M Android → ~147M procrastinators. Start with [Our school] | Funnel of pastel bars with source tags | leaving |
| 11 | Next: real students, then sync, and a free core forever. | Now / Next / Then / Sustain. Tiimo comparable. Assumption label | 4 step cards + comparable card | morning |
| 12 | [Team name] | Member cards: initial chip, name, what they built | Card grid from `TEAM` | proud |
| 13 | Thank you. Let's open the app. | Tagline, team, live demo | Large Tuck | idle (waving) |

Design: every value comes from the app's theme (`pace_colors.dart`, `pace_pastels.dart`, `pace_tokens.dart`, `pace_theme.dart`): Figtree from the app's font files, off-white page, white borderless cards with the whisper lift, radii 14/18/26/30, pastel chips at 0.31 radius, Material Symbols Rounded, no red. Slide changes use `PaceRouteTransitions` (fade + 4% rise, 300 ms, `cubic-bezier(0.23, 1, 0.32, 1)`); reduced motion fades only.

## Red flags
- Slide 8's honest-status line must stay until the real-phone check is done.

## Yellow flags
- Slide 9 feature cells: re-check competitors before the event.

## Sources
See `pitch-full.md` › Sources.
