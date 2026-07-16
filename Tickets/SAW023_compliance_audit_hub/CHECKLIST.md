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
- [x] Refresh writes `AbERP_ComplianceResult` + W snapshot
- [x] WebUI smoke on `3.27.207.215`
- [x] Commit + push

## Phase 3b — remaining categories

- [x] Seed Client / Incidents / Rostering / Documentation rules (`16-seed-remaining-rules.sql`)
- [x] Engine evaluates all categories (SA rule skipped when no date model)
- [x] Deploy JAR `7.1.0.202607161100` + WebUI Refresh smoke

## Phase 4 — Info Window + packs

- [x] Info Window **Compliance Results** (`17-audit-results-info.sql`) + menu + Admin access
- [x] Staging pack `AbilityERP-ClientUpdate-SAW023_…-20260716`
- [x] Thin prod pack `AbilityERP-ProdUpdate-SAW023_…-20260716`
- [x] DEPLOY.md / EXTERNAL-SUMMARY.md / Access tables
- [x] Commit + push
