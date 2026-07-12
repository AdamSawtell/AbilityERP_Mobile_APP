# SAW012 — Session / Process Audit performance

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#12](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/12) |
| **Slug** | `session_process_audit_perf` |
| **HCO host** | `32.236.127.117` (Test) |

## Deploy (other builds)

→ [`DEPLOY.md`](DEPLOY.md) — AD + index + HouseKeeping SQL; no JAR.

## External ticket (copy/paste)

→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)

## Goal

Restore usable **Session Audit** and **Process Audit** (core iDempiere windows) on builds where audit tables are huge — without removing audit capability. Deliver a client/Prod update pack after HCO staging loop.

## Source of truth

- `Tickets/SAW012_session_process_audit_perf/sql/` (migration SQL)
- Discovery notes: [`NOTES.md`](NOTES.md)

## Dependencies (app)

None — Application Dictionary + DB indexes + HouseKeeping only.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW012_session_process_audit_perf-*`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-*`
