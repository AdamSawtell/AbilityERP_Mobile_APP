# SAW010 — Timesheet Approval Info Window column cleanup

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#10](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/10) |
| **Slug** | `SAW010_timesheet_approval_info_columns` |
| **Source** | #901558 (05/11/2025) |

## Deploy (other builds) — agents start here

**→ [`DEPLOY.md`](DEPLOY.md)** — full install/update requirements for another build (access, SQL order, UUs, smoke, JAR caveat, packs).

Prefer thin prod pack when shipping: `Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-20260712\`

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** — paste into the customer/external ticket (not for agents).

## Goal

Clean up **Timesheet Approval** Info Window (`AD_InfoWindow_UU = 40d6a2d7-3bbc-431e-940c-ce75829a68e4`): remove unused result columns, dedupe employee display, add Break Start / Break End after Shift Type.

## Source of truth

- `idempiere-plugins/com.aberp.timesheet.approvalinfo/`
- Discovery: `scripts/db-discovery-timesheet-approval*.sql`
- Decisions / HCO variables / smoke: [`NOTES.md`](NOTES.md)
- Staging loop status: [`CHECKLIST.md`](CHECKLIST.md)

## Dependencies (app)

None — Info Window / Application Dictionary only.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW010_timesheet_approval_info_columns-20260712`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-20260712`

## Residual (client build)

Approve process execute needs host JAR for `com.aberp.timesheetapproval.processes.setstatus` — **not** in this SQL pack. See DEPLOY.md / NOTES.md.
