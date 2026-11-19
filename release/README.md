# Release checklist (Phase D4)

Drafts for the Play Store launch. None of this is published yet.

- [ ] Owner confirms prices and the free vs PACE+ split (`pace-plus.md`)
- [ ] Approve and add `in_app_purchase`, then build the wiring in `pace-plus.md`
- [ ] Check the help page phone numbers (`pace_app/lib/features/wellbeing/domain/support_contacts.dart`)
- [ ] Host `privacy-policy.md` at a public URL and add the contact email
- [ ] Fill the Data Safety form and permission declarations (`data-safety.md`)
- [ ] Content rating questionnaire
- [ ] Store listing text and graphics (`store-listing.md`)
- [ ] Release build without `PACE_GOOGLE_CLIENT_ID` (calendar hidden), signed with the upload key
- [ ] Closed test: 12+ testers for 14 days (needed for a new personal developer account).
      Record which features they use and whether they come back after a week, in `NOTES.md`
- [ ] Real-device checks still open from D1 to D3 (`NOTES.md`)
