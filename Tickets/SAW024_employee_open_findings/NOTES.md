# SAW024 — Notes

## Design (nested under Employee)

- **Employee** TabLevel 1 with `Included_Tab_ID` → **Open Findings**
- **Open Findings** TabLevel 2, physical `AbERP_ComplianceDashboard_ID` (= client) + `Parent_Column_ID` to dashboard PK
- Why = `ResultMessage`; Resolve = rule `Description` via ColumnSQL
- **Open & Fix** button → `AbERP_Compliance_OpenSource` → `AEnv.executeAsyncDesktopTask` + `AEnv.zoom(AD_Table_ID, Record_ID)`
- **Open Assignment** on the tab is a **field-level Table override** on `Record_ID` (`23-source-record-zoom-field.sql`) so Zoom opens Credential Assignment (Value display). Internal `AbERP_OpenAssignment_ID` physical column is hidden (engine still backfills it).

## Learnings

- Virtual ColumnSQL parent links fail in join SQL — use a real column
- Virtual / physical `AbERP_OpenAssignment_ID` Table field kept showing `-1` in WebUI even when DB had IDs — prefer field override on `Record_ID`
- Toolbar Zoom Across is “where used”, not polymorphic `AD_Table_ID`/`Record_ID` zoom; `@Record_ID@` is the finding PK, not column `Record_ID`
- Grid Open & Fix can hit “Exactly one selected tab is required” on included TabLevel 2 — use form view / toolbar process after selecting the row
- Host `AD_PInstance` ~28GB makes process starts slow
- Bundle version must match MANIFEST before `build.sh` or OSGi keeps the old jar

## Smoke (dev `3.27.207.215`)

- Nesting: breadcrumb `Organisation Audit > Employee > Open Findings` — pass
- 196 open Employee findings + Why / What to resolve — pass
- Open Assignment Value + Open & Fix zoom to assignment row — pending clean logout after SQL 23
- JAR active: `com.aberp.compliance_7.1.0.202607161320`

## HCO Future Deployments variables

(none yet — SQL is UU/name based)
