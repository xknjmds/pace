# PACE+ (D4): plan for when billing is approved

`in_app_purchase` is not added yet: CLAUDE.md says to ask before adding any dependency.

## Products (Play Console)

| Product id | Type | Price |
|---|---|---|
| `pace_plus_monthly` | Subscription | ₱49 / month |
| `pace_plus_yearly` | Subscription | about ₱399 / year (owner to confirm) |
| `pace_plus_lifetime` | One-time (non-consumable) | about ₱999 (owner to confirm) |

## Proposed split (owner to confirm)

- **Always free:** Today, leave-by planner, deadlines and reminders, quick capture, focus
  timer, evening check-in, recovery plan, mood, help page, welcome back, steady mode, low-energy
  mode, notes, the basic quick-capture widget, schedule import.
- **PACE+:** the app gate, extra schedule widget layouts, finance, the four-week Trends,
  self-set rewards (D6), journey extras (D5), activity suggestions (D9).
- Mental health and recovery features are never paywalled.

## Wiring

1. `core/plus/`: a `PlusStore` interface (`isActive`, `buy(product)`, `restore()`), a Play
   implementation on `in_app_purchase`, and a no-op that reports active on web and desktop.
2. Cache the last known entitlement in settings (`plus_until`, a new migration) so the app
   works offline. Give a 7-day grace period after a failed check before showing anything.
3. A lapsed subscription only hides the PACE+ entry points. It never deletes, locks or
   hides anything the user made: finance entries stay readable, and the gate turns off
   (blocking must always be escapable).
4. One calm paywall sheet ("PACE+ adds…"), reachable from each locked entry point. It never
   appears unprompted.
5. Test purchase, restore and cancel in a closed test track on a real phone.
