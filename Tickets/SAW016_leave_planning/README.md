# SAW016 — Leave Planning

| | |
|--|--|
| **Status** | in-progress (Info Window + JAR on HCO; agent deploy via `DEPLOY.md`) |
| **Kind** | idempiere |
| **GitHub** | [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16) |
| **Slug** | `SAW016_leave_planning` |
| **JAR** | `com.aberp.leave.planning_1.0.0.2026071327.jar` (requires `zcommon`) |
| **Environment** | HCO Test `32.236.127.117` |

## Deploy

See [`DEPLOY.md`](DEPLOY.md).

## External ticket

See [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md).

## Goal

Workforce **Leave Planning** window: date-only period + multi/all service locations (employee Partner Location), overlapping leave from `AbERP_Unavailability_Leave`, summaries by Approver Status / Leave Type, open underlying leave (existing submit/approve), report/export via grid + report process.

## Source of truth

- `idempiere-plugins/com.aberp.leave.planning/`

## Dependencies (app)

None.
