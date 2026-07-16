# SAW024 — Notes

## POC scope

Employee only. Pattern to copy later: Client / Incidents / Rostering / Documentation Open Findings tabs.

## Design

- TabLevel **1** sibling after Employee (TabLevel 2 broke breadcrumb tab UI on this build)
- Table `AbERP_ComplianceResult`, linked via `AD_Client_ID` + `Parent_Column_ID` = dashboard PK
- Where: category `W`, `IsResolved=N`
- Why = `ResultMessage`; Resolve = rule `Description` via ColumnSQL
- **Open Assignment** = virtual Table field (`Record_ID` → Credential Assignment) with field zoom icon
- Note: toolbar Zoom Across zooms the *finding* row, not the source — use Open Assignment zoom instead

## Smoke (2026-07-16)

- Open Findings loads **196** Employee findings with Why / What to resolve
- Parent link fixed after virtual-column join error

## HCO Future Deployments variables

(none yet)
