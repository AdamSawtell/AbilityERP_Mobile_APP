# SAW012 — Checklist

## Staging (HCO Test `32.236.127.117`)

- [x] Preflight / discovery (sizes, AD, indexes, HouseKeeping, Document Validation flood)
- [ ] Agree retention days (suggest 90)
- [ ] Write ordered UU-safe SQL (`sql/00`–`04`, optional `10` purge)
- [ ] Install on HCO
- [ ] Review: SQL verify + WebUI smoke (Process Audit + Session Audit)
- [ ] Fix loop if needed
- [ ] Append `Tickets/HCO_Deployment/LEARNINGS.md`
- [ ] Update HCO variables in NOTES

## Packs

- [ ] Staging pack `AbilityERP-ClientUpdate-SAW012_session_process_audit_perf-YYYYMMDD`
- [ ] Thin Prod pack `AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-YYYYMMDD`

## Registry / GitHub

- [x] `docs/TICKETS.md` → SAW012
- [x] GitHub #12 in-progress
- [ ] Mark done when staging green + packs ready
