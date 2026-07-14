# SAW020 — Checklist (HCO20260714)

## Ticket / release setup

- [x] Allocate SAW020 in `docs/TICKETS.md`
- [x] GitHub issue [#20](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/20) (`in-progress` → mark `done` when green)
- [x] Scaffold README / DEPLOY / EXTERNAL-SUMMARY / NOTES / CHECKLIST
- [x] Deploy all tickets in order on `54.253.165.194`
- [x] Deployment report complete
- [x] Validation matrix (install + markers + representative WebUI) Pass
- [x] LEARNINGS.md appended
- [x] HCO_Deployment README host row updated for this release host
- [x] Mark Ready for next HCO Production deployment
- [ ] Commit + push
- [ ] GitHub issue → `done`

## Per-ticket deploy (Test dry run)

| # | Ticket | Preflight | Install | Verify SQL | Cache/Restart | WebUI smoke | Notes |
|---|--------|-----------|---------|------------|---------------|-------------|-------|
| 1 | SAW018 | [x] | [x] | [x] | [x] | [x] | Client needed clean stop |
| 2 | SAW001 | [x] | [x] | [x] | [x] | [ ] | DB markers Pass |
| 3 | SAW003 | [x] | [x] | [x] | [x] | [ ] | JAR 1237 + restart |
| 4 | SAW007 | [x] | [x] | [x] | [x] | [ ] | Activity tab seen on Support Location |
| 5 | SAW009 | [x] | [x] | [x] | [x] | [ ] | Fields present |
| 6 | SAW010 | [x] | [x] | [x] | [x] | [ ] | Break cols present |
| 7–8 | SAW013 | [x] | [x] | [x] | [x] | [ ] | Request Submitted present |
| 9 | SAW015 | [x] | [x] | [x] | [x] | [ ] | Process + JAR |
| 10 | SAW014 | [x] | [x] | [x] | [x] | [x] | Grid Email/Phone Pass |
| 11 | SAW017 | [x] | [x] | [x] | [x] | [ ] | Bulk + DocList + YesNo |

## Release readiness

- [x] Application starts (WebUI 200)
- [x] DB migrations completed
- [x] Server recover after PackIn/restarts
- [x] Smoke representative enhancement (SAW014) + Admin login
- [x] Rollback notes recorded
- [x] Production runbook (`DEPLOY.md` + report) matches actual steps
