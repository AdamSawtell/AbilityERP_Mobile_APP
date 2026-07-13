# SAW015 — Checklist

## Ticket bootstrap

- [x] Allocate SAW015; GitHub #15; Agents chat renamed
- [x] `Tickets/SAW015_skip_dates_copy_from/` scaffold
- [x] `docs/TICKETS.md` registry row

## Discovery

- [ ] Service Booking copy-lines process (class, AD, UX)
- [ ] Skip Dates / Dates table schema + window/tab UUs
- [ ] Decide JAR vs SQL-only

## Implementation

- [ ] Process + parameter (source Skip Dates)
- [ ] Copy logic (new IDs, target FK, source read-only)
- [ ] Date-review warning / confirmation
- [ ] Copy-count success message
- [ ] Button / toolbar on Skip Dates header
- [ ] AbilityERP Admin + Admin process access (by role name)
- [ ] Preflight / install / verify / rollback SQL
- [ ] Fixed UUs for new AbERP objects

## Staging loop

- [ ] Preflight
- [ ] Install
- [ ] Cache Reset / restart if JAR
- [ ] WebUI smoke (copy, warning, count, source unchanged, edit target)
- [ ] Fix until green

## Packs / UAT

- [ ] Staging pack `AbilityERP-ClientUpdate-SAW015_…`
- [ ] Thin prod pack `AbilityERP-ProdUpdate-SAW015_…`
- [ ] Deploy to test for customer UAT
- [ ] Update EXTERNAL-SUMMARY / DEPLOY / NOTES
- [ ] GitHub → done when UAT accepted
