# SAW026 — Vehicle Activity tab

| | |
|---|---|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#26](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/26) |
| **Slug** | `SAW026_vehicle_activity_tab` |

## Goal

Add the standard AbilityERP **Activity** tab to the **Vehicle** window (`AbERP_Vehicle`), following the portable SAW007 Contact Activity pattern.

The Activity Type list must include Email, Meeting, Phone call, Case Note, and Task.

The delivered layout hides User/Contact and Contact Activity from the form and
grid, gives Comments four visible lines, and limits the grid to Start Date,
Activity Type, Description, Comments, End Date, and Complete.

## Deploy

See [`DEPLOY.md`](DEPLOY.md).

Executable repository artifacts and their order are listed in
[`ARTIFACTS.md`](ARTIFACTS.md). A new agent should use the wrappers under
[`sql/`](sql/) rather than depending on workstation-specific Downloads paths.

## External ticket

See [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md).

## Source of truth

- Apply: `idempiere-plugins/com.aberp.contactactivity.tabs/sql/05-add-vehicle-activity-tab.sql`
- Verify: `idempiere-plugins/com.aberp.contactactivity.tabs/sql/95-verify-vehicle-activity-tab.sql`
- Rollback: `idempiere-plugins/com.aberp.contactactivity.tabs/sql/99-rollback-vehicle-activity-tab.sql`

## Dependencies (app)

None.

## Packs

- `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW026_vehicle_activity_tab-20260717\`
- `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW026_vehicle_activity_tab-20260717\`

These local pack paths are secondary handoff copies. Deployment from a fresh
checkout uses this ticket's `sql/` wrappers.
