# SAW016 — Deploy to another build (agent)

**Ticket / slug:** `SAW016_leave_planning`  
**Kind:** idempiere · **JAR:** Yes · **Status:** in-progress  
**GitHub:** [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16)

## Required host access

- SSH · `psql` · WebUI Admin · restart / OSGi  
- Java 11 + `$IDEMPIERE_HOME` to build the Info Window JAR

## Agent one-liner (Info Window + Java — current path)

```bash
cd idempiere-plugins/com.aberp.leave.planning
chmod +x build.sh deploy.sh
./deploy.sh
# builds JAR 1.0.0.2026071327 → SQL 14 + 15 → restart → wait WebUI 200
# Cache Reset / logout-in. Do NOT wipe OSGi configuration cache.
```

**OSGi requirement (P0):** `META-INF/MANIFEST.MF` must include **`zcommon`** on `Require-Bundle` (Export CSV / `AMedia`). Without it, WebUI can throw `ClassNotFoundException: org.zkoss.util.media.Media` and block other Info Windows on the same host.

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.leave.planning/` |
| Symbolic name | `com.aberp.leave.planning` |
| Version | **`1.0.0.2026071327`** |
| Info Window UU | `16a016iw-c0d4-4f01-8e15-000000000001` |
| UI class | `com.aberp.leave.planning.info.LeavePlanningInfoWindow` |
| Deploy SQL (JAR path) | `sql/14-info-readonly.sql`, `sql/15-info-summary-functions.sql` |

## First-time AD install (new build without Leave Planning)

If the Info Window / tables do not exist yet, run the AD pack **before** `./deploy.sh`:

```bash
cd idempiere-plugins/com.aberp.leave.planning/sql
# optional: 00-bump-sequences.sql if nextid collides
psql -d idempiere -U adempiere -v ON_ERROR_STOP=1 \
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
  -f 07-verify.sql
# then: cd .. && ./deploy.sh
```

Rollback AD: `99-rollback.sql` (extend for line table/functions as needed).

## AbilityERP Admin access

Window / Info **Leave Planning** + process **Leave Planning Report** granted by role **name** to AbilityERP Admin, Admin, Rostering, Rostering TL, People and Culture, Manager People and Culture (and mirrored from Unavailability & Leave access). Smoke **as Admin**.

## Portability risks

- Primary UX is the **Info Window** (menu action `I`), not the soft-retired record window.  
- Never change existing client `*_UU` on HCO.  
- HCO WebUI: check `http://127.0.0.1/webui/` or Jetty **8083** (not always 8080).  
- Missing `zcommon` breaks Export CSV and can surface Media errors when other Info Windows open.

## WebUI smoke

1. Cache Reset + re-login as Admin.  
2. Menu → **Leave Planning** (Info).  
3. Set Planning Start / End → Search.  
4. Banner status totals; grid read-only on selection.  
5. **Export CSV** must not throw Media / ClassNotFound.  
6. Zoom leave → existing Submit Leave / Approver Status.

## Environments

| Env | Bundle | Notes |
|-----|--------|-------|
| HCO Test `32.236.127.117` | `1.0.0.2026071327` | `zcommon` fix applied 2026-07-13 |

## External ticket text

`Tickets/SAW016_leave_planning/EXTERNAL-SUMMARY.md`
