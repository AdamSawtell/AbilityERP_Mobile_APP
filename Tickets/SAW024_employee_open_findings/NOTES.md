# SAW024 — Notes

## Design (nested under Employee)

- **Employee** TabLevel 1 with `Included_Tab_ID` → **Open Findings**
- **Open Findings** TabLevel 2, physical `AbERP_ComplianceDashboard_ID` (= client) + `Parent_Column_ID` to dashboard PK
- Why = `ResultMessage`; Resolve = rule `Description` via ColumnSQL
- Visible **Assignment** = String ColumnSQL of Credential Assignment **Value** (`25-*.sql`)
- Hidden `AbERP_SourceAssignment_ID` holds the CA PK for the process
- **Open & Fix Source** (`AbERP_Compliance_OpenSource`) → OSGi-load `AEnv` → `executeAsyncDesktopTask` + `zoom(table, record)`
- Menu folder renamed **Organisation Audit**; window leaf **Audit Hub** under it (`27-*.sql`) — same-named folder+leaf hides the window in WebUI


## Learnings

- Virtual ColumnSQL parent links fail in join SQL — use a real column
- Table lookup fields named like / bound to `Record_ID` on included tabs show `-1` (context clash with window `@Record_ID@`)
- Grid Button columns on TabLevel 2 stay disabled — use toolbar **Process → Open & Fix Source**
- Plain `Class.forName("org.adempiere.webui.apps.AEnv")` fails from process OSGi bundle — load via `Bundle.loadClass` on `org.adempiere.ui.zk`
- Same-named summary folder + window menu hides the window leaf in WebUI tree
- Host `AD_PInstance` ~28GB makes process starts slow
- Bundle version must match MANIFEST before `build.sh` or OSGi keeps the old jar

## Smoke (dev `3.27.207.215`)

- Nesting: breadcrumb `Organisation Audit > Employee > Open Findings` — pass
- 196 open Employee findings + Why / What to resolve — pass
- Assignment column shows CA Value (e.g. `1003317`) not `-1` — pass
- Process → Open & Fix Source → tab **Credential Assignment: 1003317** — pass
- JAR active: `com.aberp.compliance_7.1.0.202607161500`

## HCO Future Deployments variables

(none yet — SQL is UU/name based)
