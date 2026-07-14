# SAW016 — Deploy to another build (agent)

**Ticket / slug:** `SAW016_leave_planning`  
**Kind:** idempiere · **JAR:** Yes · **Status:** in-progress (redeploy after HCO rebuild)  
**GitHub:** [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16)

Use this file alone to install Leave Planning on a clean or rebuilt HCO / client host.

## Required host access

| Need | HCO Test |
|------|----------|
| SSH | `ubuntu@32.236.127.117` — key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| DB | `psql` · `idempiere` / `adempiere` / `flamingo` |
| WebUI | `http://32.236.127.117/webui/` · `SuperUser` / `HCOflamingo` · role **Admin** |
| Build | Java 11 on host · `$IDEMPIERE_HOME=/opt/idempiere-server` |
| Plugin tree | `/opt/idempiere-server/AbERP/com.aberp.leave.planning/` (upload from repo) |

Also: `.cursor/rules/hco-deployment.mdc` — **never change HCO `*_UU` values**.

## Package

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.leave.planning/` |
| Symbolic name | `com.aberp.leave.planning` |
| JAR version | **`1.0.0.2026071402`** |
| Info Window UU | `16a016iw-c0d4-4f01-8e15-000000000001` |
| UI class | `com.aberp.leave.planning.info.LeavePlanningInfoWindow` |
| Val rule UU | `16a01606-c0d4-4f01-8e15-000000000001` |
| Display SQL | `aberp_lp_primary_support_location(u.AD_User_ID)` |
| Support Location criteria | **Search (30)** + ref `159` + Support Location val rule — **not** Table Direct |

**Export CSV:** `Filedownload.save(byte[])` — do **not** require `zcommon` / `AMedia`.

## Agent one-liner (HCO after server rebuild)

From a Windows agent workspace (PowerShell):

```powershell
$pem = "$env:USERPROFILE\.ssh\HCObusiness.pem"
$src = "idempiere-plugins\com.aberp.leave.planning"
# 1) Upload plugin tree
ssh -i $pem -o StrictHostKeyChecking=no ubuntu@32.236.127.117 "mkdir -p /opt/idempiere-server/AbERP/com.aberp.leave.planning"
scp -i $pem -o StrictHostKeyChecking=no -r "$src\*" ubuntu@32.236.127.117:/opt/idempiere-server/AbERP/com.aberp.leave.planning/
# 2) On host: apply SQL + build JAR + hard-start WebUI
ssh -i $pem -o StrictHostKeyChecking=no ubuntu@32.236.127.117 "bash /opt/idempiere-server/AbERP/com.aberp.leave.planning/redeploy-hco.sh"
```

Or on the host already:

```bash
cd /opt/idempiere-server/AbERP/com.aberp.leave.planning
sed -i 's/\r$//' redeploy-hco.sh rebuild-hco.sh sql/*.sql
bash redeploy-hco.sh
```

`redeploy-hco.sh` applies ordered SQL (idempotent), builds JAR **1402**, updates `bundles.info`, and force-restarts iDempiere if WebUI stays HTTP 000.

**Do NOT wipe OSGi `configuration/` cache** unless the host is already dead.

## SQL order (plugin `sql/`)

### A — First-time AD (Info missing)

```bash
cd /opt/idempiere-server/AbERP/com.aberp.leave.planning/sql
export PGPASSWORD=flamingo
psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 \
  -f 00-preflight.sql \
  -f 01-create-table.sql \
  -f 08-summary-functions.sql \
  -f 02-ad-table-columns.sql \
  -f 03-leave-virtual-columns.sql \
  -f 04-window-tabs-fields.sql \
  -f 09-planning-line.sql \
  -f 10-ad-planning-line.sql \
  -f 05-menu-access.sql \
  -f 06-report.sql \
  -f 07-verify.sql \
  -f 11-info-window.sql \
  -f 12-fix-info-locations.sql \
  -f 13-simplify-service-location.sql \
  -f 14-info-readonly.sql \
  -f 15-info-summary-functions.sql \
  -f 16-hide-grid-columns.sql \
  -f 17-risk-sort-order.sql \
  -f 18-support-location-valrule.sql \
  -f 19-fix-service-location-roster.sql \
  -f 20-fix-service-location-parser.sql \
  -f 21-primary-service-location.sql \
  -f 22-primary-location-function.sql \
  -f 23-rename-support-location.sql \
  -f 24-support-location-search-nonneg.sql
```

### B — Incremental (Info Window already exists)

Minimum required after rebuild if AD was restored without these patches:

```text
14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
```

**24 is mandatory** on every redeploy until baseline Info columns ship as Search (30).  
**22 is mandatory** — nested SELECT in grid selectclause breaks AccessSqlParser.

Rollback (destructive): `99-rollback.sql`.

## Known bugs fixed in this stream (verify after install)

| Symptom | Fix |
|---------|-----|
| Search popup `IllegalArgumentException` / mangled SQL | `22` → `aberp_lp_primary_support_location(...)` |
| Filter/grid used home address (Mount Barker…) | `18`–`19` roster EXISTS + Support Location val rule |
| **“Only non-negative number is allowed”** on Support Location | `24` Search(30) + JAR sanitize / hide All-Any / client Intbox strip |
| Label still “Service Location” | `23` rename → **Support Location** |
| Media ClassNotFound on Export CSV | JAR uses `Filedownload.save(byte[])` — no `AMedia` |

## WebUI hard restart (HCO)

`systemctl restart idempiere` often leaves HTTP **000** while claiming “already running”. Prefer:

```bash
# Stop + kill equinox + start; poll :8080/webui until 200
bash /home/ubuntu/restart-webui.sh
# or plugin helper:
bash /opt/idempiere-server/AbERP/com.aberp.leave.planning/tmp-force-up.sh   # if present
# manual:
sudo /etc/init.d/idempiere stop || true
sudo pkill -9 -f 'org.eclipse.equinox.launcher' || true
sudo /etc/init.d/idempiere start
# poll http://127.0.0.1:8080/webui/ until 200 (nginx :80 proxies Jetty)
```

Then: **Cache Reset** (menu) or logout/in as Admin before smoke.

## Verify after install

```bash
grep leave.planning /opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
# expect: com.aberp.leave.planning,1.0.0.2026071402,...

PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere -c "
SELECT ic.columnname, ic.name, ic.ad_reference_id, left(ic.selectclause,60)
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu='16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.columnname IN ('C_BPartner_Location_ID','AbERP_LP_ServiceLocation');
"
# criteria C_BPartner_Location_ID: name=Support Location, ad_reference_id=30
# display AbERP_LP_ServiceLocation: selectclause=aberp_lp_primary_support_location(...)
```

## WebUI smoke (must all pass)

Log in as **Admin**. Menu → **Leave Planning** (Info, not Report).

1. Labels show **Support Location** (criteria + grid).  
2. Planning Start/End = Jul 2026 → ReQuery → ~**46** rows, **no** IllegalArgument popup.  
3. Grid Support Location = roster sites (Murray / Gawler / Centennial…), not home suburbs.  
4. Pick Support Location via Search (`1/6 Murray`) → ReQuery → **no** “non-negative” popup; fewer rows (~9).  
5. Banner status links: Declined / Approved / All.  
6. Approver Status colours (rose / green).  
7. Export CSV downloads without Media CNFE.  
8. Zoom a leave row opens Submit Leave / Approver Status.

## AbilityERP Admin access

Grants by role **name** in SQL (`05-menu-access.sql` / Info access): AbilityERP Admin, Admin, Rostering, Rostering TL, People and Culture, Manager People and Culture. Smoke as **Admin** on HCO.

## Portability

- Resolve by `*_UU` / name — never hardcode `AD_*_ID`.  
- Never overwrite existing client `*_UU` on HCO.  
- Primary UX = Info Window action `I` (record window soft-retired).

## Environments

| Env | Bundle | Notes |
|-----|--------|-------|
| HCO Test `32.236.127.117` | `1.0.0.2026071402` | Rebuild handoff 2026-07-14 — use `redeploy-hco.sh` |

## External ticket text

`Tickets/SAW016_leave_planning/EXTERNAL-SUMMARY.md`
