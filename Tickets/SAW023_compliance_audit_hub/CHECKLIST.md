# SAW023 — Checklist

## Skeleton

- [x] GitHub #23 + TICKETS.md
- [x] Plugin SQL 00–13 authored
- [x] Install on `3.27.207.215`
- [x] Restart/cache + WebUI smoke (NDIS Audit Tool + Organisation Audit + category tabs)
- [x] Commit + push

## Phase 2 — Refresh + OSGi

- [x] `com.aberp.compliance` OSGi JAR + `IProcessFactory`
- [x] Process `AbERP_Compliance_Refresh` + Organisation Audit button
- [x] Deploy on `3.27.207.215` + WebUI stub smoke
- [x] Commit + push

## Phase 3 — Employee rules

- [x] Seed 3 Employee rules (`15-seed-employee-rules.sql`)
- [x] `ComplianceEngine` evaluates credential assignment expiry / 30d / screening
- [x] Refresh writes `AbERP_ComplianceResult` + W snapshot (carry-forward other cats)
- [x] WebUI smoke on `3.27.207.215` (123/65/8 findings)
- [ ] Commit + push

## Later

- [ ] Phase 3b — Client / Incidents / Rostering / Documentation rules
- [ ] Phase 4 — Info Window + client packs
