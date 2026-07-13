# SAW018 — Deploy to another build (agent)

**Ticket / slug:** `SAW018_hco_release_packins`  
**GitHub:** [#18](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/18)  
**Kind:** idempiere · **JAR:** No · **Status:** HCO Test installed 2026-07-13

Point agents here. Source packins live under `packins/` (copied from `D:\HCO Release Packins`).

## Required host access

| Need | Why |
|------|-----|
| SSH to iDempiere host | Copy zips + run SQL / PackInFolder |
| `psql` on `idempiere` / `adempiere` | View SQL + stuck-import clear + verify |
| WebUI **System** / **System Administrator** | Preferred: **Apply Pack In from Folder** |
| Optional: `utils/RUN_ApplyPackInFromFolder.sh` | Works after Incremental2Pack blockers cleared |

## Agent one-liner (preferred on live server)

```bash
# 1) Optional: clear stuck Installing imports
psql -d idempiere -U adempiere -v ON_ERROR_STOP=1 -f sql/00-clear-stuck-package-imp.sql

# 2) DB view BEFORE credentials packin
psql -d idempiere -U adempiere -v ON_ERROR_STOP=1 -f sql/01-hco_cred_missing_staff_v.sql

# 3) Rename zips to Apply Pack In convention (Client Value = SYSTEM)
mkdir -p /tmp/saw018-named
cp packins/hco_credentials.zip     /tmp/saw018-named/$(date +%Y%m%d%H%M)_SYSTEM_hco_credentials.zip
# … employee, client, supportlocation with +1 minute timestamps each
# Or use pre-named copies under Downloads pack packins/named/

# 4) Apply (WebUI System Admin → Apply Pack In from Folder → Folder path)
#    OR (after employee.infopanel Incremental2Pack is not failing):
cd /opt/idempiere-server/utils
sudo -u idempiere ./RUN_ApplyPackInFromFolder.sh /tmp/saw018-named

# 5) Verify + Cache Reset
psql -d idempiere -U adempiere -f sql/02-verify.sql
```

**Thin prod pack:** `Downloads\AbilityERP-ProdUpdate-SAW018_hco_release_packins-20260713\`  
**Full staging pack:** `Downloads\AbilityERP-ClientUpdate-SAW018_hco_release_packins-20260713\`

## Packin order (mandatory)

1. `hco_cred_missing_staff_v` SQL view  
2. `*_SYSTEM_hco_credentials.zip`  
3. `*_SYSTEM_hco_employee.zip` (package name inside: `hco_client_employee`)  
4. `*_SYSTEM_hco_client.zip`  
5. `*_SYSTEM_hco_supportlocation.zip` (`UpdateDictionary=false` — Support Location UU must stay)

Filename rule for folder apply: `yyyymmddHHMM_SYSTEM_<info>.zip`  
(`AD_Client.Value` for System is **`SYSTEM`** — case-sensitive.)

## What gets installed

| Artifact | Contents (summary) |
|----------|-------------------|
| credentials | AD_Table `hco_cred_missing_staff_v` UU `598a7584-…`, element `hco_primarydept` UU `daca9cb3-…`, tab/fields |
| employee | Employee/HCO form elements, refs, processes (Submit Master Location / Recur Lines / Document Validation) |
| client | Client/HCO AD fields/elements/processes |
| supportlocation | Support Location window UU `6ef3c558-…` + related tables (same UUs as existing HCO — do **not** overwrite UUs) |
| SQL view | `adempiere.hco_cred_missing_staff_v` |

## AbilityERP Admin access

No new menu window owned by this ticket beyond existing Support Location / Credentials surfaces. Smoke as **Admin** (HCO) after System packin. Grant AbilityERP Admin only if a new menued object appears on a fresh client.

## Known HCO blockers (fixed in process)

1. **Stuck `ad_package_imp`** (`processed=N`, `Installing`) — run `sql/00-clear-stuck-package-imp.sql`.  
2. **Legacy `com.aberp.employee.infopanel` Incremental2Pack** — fails saving InfoWindow “Employee (User) / Agency Staff Rostering Info” (conflicts with SAW003 `com.aberp.rostering.staffinfo`). On HCO we marked 7.1.3–7.1.12 as Completed successfully and uninstalled OSGi bundle `com.aberp.employee.infopanel` (inputstream install). Prefer staffinfo JAR going forward.  
3. **`RUN_ApplyPackInFromFolder.sh` stops the PackIn OSGi app** after apply — ensure `systemctl start idempiere` if WebUI drops. Prefer WebUI **Apply Pack In from Folder** on a live server when possible.

## Smoke (HCO Test 2026-07-13)

| Check | Result |
|-------|--------|
| All 4 named zips `Completed successfully` | Pass (`1001055`–`1001058`) |
| View `hco_cred_missing_staff_v` | Pass |
| AD_Table UU `598a7584-…` | Pass |
| Element `hco_primarydept` UU `daca9cb3-…` | Pass |
| Support Location window UU unchanged `6ef3c558-…` | Pass |
| WebUI up after apply | Pass |

## Rollback

2Pack uninstall via Package Maintenance (per package) — high risk on Support Location. Prefer restore from DB backup. View: `DROP VIEW IF EXISTS adempiere.hco_cred_missing_staff_v;`
