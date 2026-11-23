# Verification report: PACE pitch (v2, 5 minutes)

*Skill: startup-pitch | Generated: 2026-11-19*

Run inline against `deck.html` and every `pitch-*.md` after the rebuild to follow the Topic 08 guide.

## Summary
**0 Critical · 3 Warnings · 2 Info.** OK to present.

## Arithmetic checks
| Claim | Check | Result |
|---|---|---|
| Budget total ₱4,500 | 1,500 + 1,000 + 1,600 + 400 | Pass |
| Thank-you load ₱1,500 | 30 × ₱50 | Pass |
| Buffer ≈ 10% | 400 ÷ 4,100 = 9.8% | Pass |
| US$25 ≈ ₱1,600 | 25 × ~64 = 1,600 | Pass |
| ₱94/h | 755 ÷ 8 = 94.4 | Pass (rounded down) |
| 110 min/month | 5 × 22 | Pass |
| ₱172 value | 110/60 × 94 = 172.3 | Pass |
| Net ₱123 | 172 − 49 | Pass |
| ROI 251% | (172 − 49) ÷ 49 = 2.51 | Pass |
| Break-even 1.4 min/day | 49 ÷ 94 h = 31.3 min ÷ 22 = 1.42 | Pass |
| ₱399/year "about 32% less" | 1 − 399 ÷ (49 × 12 = 588) = 32.1% | Pass |
| ~147M | 269M × 0.728 × 0.75 = 146.9M | Pass |
| Timing 4:45 | sum of slide times | Pass |

## Consistency checks
| Check | Result |
|---|---|
| Deck ↔ 5-min script ↔ 2-min ↔ 1-min ↔ summary note | Pass: same price, ask, pilot size, weeks and figures |
| Pilot timing | Pass: tests in weeks 1–2, pilot weeks 3–10 (8 weeks), report by week 10 |
| Labels | Pass: validation marked "Planned · no results yet"; ROI marked "Modeled · assumptions"; story marked "Illustrative" |
| Guide sections | Pass: all 10 present, in the guide's order |

## Warnings
1. **NCR wage order ambiguity.** ₱755/day is consistent across sources, but the order number and start date conflict. Check the DOLE/RTWPB page before quoting a wage order.
2. **Budget estimates.** Printing and the peso rate are estimates. The pilot is one classroom (30), a first signal rather than a representative sample.
3. **Alternatives table** is our reading of public product pages.

## Info
- "Google Play's closed-testing step for new apps" is stated without numbers on purpose; check Google's current requirement for new personal developer accounts before quoting specifics.
- Pilot success thresholds in the appendix (50% retention, 10% pre-order) are a proposal.

## Visual checks
- All 13 slides rendered at 1600×900 (light). No overflow, Tuck never cropped, every placeholder filled from `TEAM`.
- New icons (alarm, calculate, campaign, cloud_sync, fact_check, flag, handshake, quiz, smartphone, storefront, verified) added to the local icon subset; all icons used are present.
