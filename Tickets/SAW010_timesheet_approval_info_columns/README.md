# SAW010 — Timesheet Approval Info Window column cleanup

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#10](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/10) |
| **Slug** | `timesheet_approval_info_columns` |
| **Source** | #901558 (05/11/2025) |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — SQL pack for Info columns; approval process JAR is a separate host dependency.

## Goal

Clean up **Timesheet Approval** Info Window (`AD_InfoWindow_UU = 40d6a2d7-3bbc-431e-940c-ce75829a68e4`): remove unused result columns, dedupe employee display, add Break Start / Break End after Shift Type.

## Source of truth

- `idempiere-plugins/com.aberp.timesheet.approvalinfo/`
- Discovery: `scripts/db-discovery-timesheet-approval*.sql`

## Dependencies (app)

None — Info Window / Application Dictionary only.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW010_timesheet_approval_info_columns-*`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-*`
