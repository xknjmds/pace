# Full pitch (~8 min + demo): PACE

*Skill: startup-pitch | Generated: 2026-11-19*

Audience: student startup competition judges. This script follows the deck slide by slide (`deck.html`); the same notes are in `presenter-notes.pdf`. Timing adds up to about 8:20 spoken, plus a 60-second live demo. For a 5-minute slot use `pitch-5min.md`.

**Ordering rationale.** PACE has no traction yet, so the pitch leads with the thing judges can feel: the morning problem. It then lands the insight early (slide 4), shows the working product, and only then turns to market and next steps. The strongest proof we have is that it's **built and tested**, so that gets its own slide right after the product.

---

## 1. Title (0:20)
> Hi, we're [Team name]. This is PACE, and this is Tuck. PACE stands for *Progress Always Comes Eventually*. Hold that phrase; the whole app is built around it.

*Notes:* Smile, pause, move on. Don't explain Tuck yet.

**Transition:** "So what does it do?"

## 2. What PACE does (0:40)
> Here's PACE in one sentence: it tells you what to do right now.
> You type four things once: when class starts, how long the commute is, how long you take to get ready, and breakfast. PACE works backwards: up at 06:30, eat at 06:50, out the door at 07:35. Each one rings at the right time. And if you oversleep, it doesn't show you everything you missed; it shows one next step.

*Notes:* Point at the four time tiles. They are real outputs of `computeLeaveByPlan` for 08:00 / 25 / 30 / 15.

**Transition:** "Why did we build this?"

## 3. Problem (0:50)
> This started with a real person: one of us. No daily system. Bedtime moving around, late to class, breakfast skipped, assignments remembered the night they were due, and on top of that, recovering from burnout.
> Here's the thing: to-do apps store the due date, but they never tell you when to start. And habit apps reset your streak to zero the first day you slip, which feels terrible when you're already tired.
> And it's not just us: about three in four college students call themselves procrastinators.

*Notes:* Pause. Ask: "Who here has been late because nothing told them to leave?" Let the judges react; that's engagement, not lost time.

**Transition:** "We think most apps get one thing wrong."

## 4. Insight (0:45)
> People who are behind don't need more lists. They need one nudge at the right moment, and forgiveness when they miss it.
> Most apps store tasks, reset streaks, and show you everything you missed. Research backs up how that feels: when an app highlights a broken streak, people are less likely to keep going. PACE flips each of those. It works out when to start, it counts what you did, and when you're late it gives you one step.

*Notes:* Slow down on the headline. This is the line judges should remember.

## 5. Today screen (1:00)
> This is the Today screen. Open the app, and the first thing you see is "Right now": the next step and its time. Tap a step when it's done and a stone fills in. Three stones, like the ones on Tuck's shell. Below that: the three things you picked last night, and what's due soon.
> Now the important part. If you wake up late, PACE doesn't go red and list your failures. It switches to "One thing now: Leave now. You arrive about 08:05." One button. Out the door.

*Notes:* Point at the warm card. All copy on screen is the real app copy.

## 6. Deadlines and Just start (0:45)
> Deadlines get four reminders: three days before, the day before, the morning of, and two hours before. Each one is a little closer.
> Two buttons make it kind. "Not today" quiets it for the day, and that isn't counted as a miss. "Submitted" cancels the rest.
> And when it's time to work, there's Just start: a ten-minute timer. Starting is the hard part. After ten minutes you can keep going, or stop here, guilt-free.

## 7. Forgiving by design (0:40)
> This is what makes PACE different in how it feels. Low-energy mode: on a bad day, every screen shrinks to just the next two days. No streaks: we count days done this week, and it never drops to zero. No red: being late is shown in a warm morning colour.
> And Tuck has one rule: Tuck is never sad, never disappointed. That's the brand.

*Notes:* Light moment: "Tuck tucks in when you need rest. That's the whole joke, and we're sticking with it."

## 8. Built and working (0:45)
> This isn't a concept. It's built. 335 automated tests, about 18,600 lines of Flutter code we wrote, thirteen feature modules. All the scheduling logic, like "when should I wake up", is plain code with its own unit tests, so we can prove the times are right. No account. No server. Your data never leaves your phone.
> To be honest with you: we don't have users beyond ourselves yet, and we're still checking reminder timing on real phones. That's our next step.

*Notes:* The honesty line earns trust. Say it plainly, not apologetically.

## 9. Landscape (0:40)
> People always ask "isn't this just Todoist, or a calendar?" Those apps store what and when it's due. Planners like Tiimo and Structured give you a nice timeline, but you still fill it in yourself. Habitica turns tasks into a game where you lose health when you miss.
> PACE fills the morning in for you from one input, rebuilds it when you're late, and never punishes. And Tiimo's success, half a million users and App of the Year, tells us people really want calm planners.

## 10. Who it's for (0:35)
> We counted from the bottom up. 269 million university students worldwide, from UNESCO. About 73% of phones run Android, so roughly 196 million. About three in four call themselves procrastinators: around 147 million people. That's an estimate, and it's only university students; high school would add more.
> But we're starting small: [Our school], with students we can actually talk to.

## 11. What's next (0:35)
> First, a pilot with classmates: real phones, real mornings, and we watch where it still breaks. Then optional accounts and sync, so your plan follows you between devices.
> To keep it running, the core planner stays free forever. Extras like sync and backup could be paid. Tiimo does something similar: about one in ten users pay. We're upfront that this is a plan we still have to test.

## 12. Team (0:25)
> We're [Team name]. *(Each member: name + one thing they built, one sentence.)*

## 13. Close (0:20)
> PACE: the app that tells you what to do right now, and never makes you feel bad when you're behind. Thank you. Let us show you the app.

**Demo (60 s):** Today → tap "Leave" → Deadlines tab → open a task → Just start → back to More → turn on low-energy mode and show Today shrinking.
Then: "We'd love your questions."

---

## Red flags
- **No users yet.** Judges will ask. Answer with the pilot plan (slide 11), not excuses.
- **Reminders not verified on a real phone yet** (`NOTES.md`, M2). Don't claim they "work reliably" until the check is done. If the demo depends on a reminder firing, rehearse on the demo phone first.

## Yellow flags
- The market funnel is an estimate that assumes students match the global Android share.
- The paid tier is an untested assumption.
- The comparison table reflects our reading of public pages; re-check before the event.

## Sources
- UNESCO higher-education enrolment, 269M (2024): https://thepienews.com/global-he-enrolment-reaches-269-million-as-student-mobility-triples/
- StatCounter Android share 72.77% (Nov 2025), via https://backlinko.com/iphone-vs-android-statistics and https://searchengineland.com/guide/iphone-vs-android-statistics
- ~75% of college students self-identify as procrastinators (Steel & Ferrari 2013, cited in): https://pmc.ncbi.nlm.nih.gov/articles/PMC8766341 · https://www.frontiersin.org/articles/10.3389/fpsyg.2021.719425/full
- Broken streaks and persistence (University of Delaware, INSEAD summary): https://knowledge.insead.edu/marketing/consumer-streaks-are-motivating-the-key-is-keeping-them-alive-19011
- Tiimo users, funding, freemium: https://en.wikipedia.org/wiki/Tiimo · https://www.tiimoapp.com/newsroom · https://www.tiimoapp.com/blog/why-tiimo-went-freemium
- Codebase facts: `pace_app/` (335 tests in 59 files, ~18.6k non-generated Dart lines, counted 2026-11-19)
