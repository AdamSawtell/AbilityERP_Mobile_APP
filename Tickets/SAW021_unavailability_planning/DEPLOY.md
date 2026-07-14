# SAW021 — Deploy to another build (agent)

**Ticket / slug:** `SAW021_unavailability_planning`  
**Kind:** idempiere · **JAR:** Yes · **Status:** in-progress  
**GitHub:** [#21](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/21)

## Required host access

- SSH · `psql` · WebUI Admin · restart / OSGi  
- Java 11 + `$IDEMPIERE_HOME`  
- Develop host: `ubuntu@13.210.248.141` — key `c:\Users\sawte\Documents\SSH Keys\HCObusiness.pem`

## Agent one-liner

```bash
cd /opt/idempiere-server/AbERP/com.aberp.unavailability.planning
# or upload from repo: idempiere-plugins/com.aberp.unavailability.planning/
bash rebuild-hco.sh
# If systemd restart is a no-op ("already running"), force-start:
sudo bash /opt/idempiere-server/AbERP/com.aberp.leave.planning/force-start-webui.sh
# Cache Reset / logout-in. JAR-only iterate: bash redeploy-jar.sh
```

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.unavailability.planning/` |
| Symbolic name | `com.aberp.unavailability.planning` |
| Version | **`1.0.0.2026071402`** |
| Info Window UU | `21a021iw-c0d4-4f01-8e15-000000000001` |
| Menu UU | `21a02105-c0d4-4f01-8e15-000000000001` |
| UI class | `com.aberp.unavailability.planning.info.UnavailabilityPlanningInfoWindow` |
| SQL order | `00-preflight` → `01-functions` → `02-info-window` → `03-verify` |
| WebUI | `http://13.210.248.141/webui/` · SuperUser / `HCOflamingo` · role **Admin** |

## AbilityERP Admin access

Info Window granted by role **name** to AbilityERP Admin, Admin, Rostering, Rostering TL, People and Culture, Manager People and Culture — mirrored from Ongoing Unavailability / Unavailability & Leave window access.

## Portability risks

- Never hardcode `AD_*_ID` — UU/name lookups.  
- Never change existing HCO `*_UU`.  
- Nested SELECT in InfoColumn selectclause breaks AccessSqlParser — use `aberp_up_*` functions.  
- Export CSV: `Filedownload.save(byte[])` only (no `zcommon`/`AMedia`).  
- No Leave Type on Ongoing.  
- `systemctl restart idempiere` may no-op if PID file stale — use force-start script.

## WebUI smoke

1. Cache Reset / re-login as Admin.  
2. Menu → **Unavailability Planning**.  
3. Planning Start/End e.g. 01/01/2027–31/01/2027, ReQuery.  
4. Expect ~49 headers; banner “Headers / Day lines / With pattern”; Unavailable Pattern column populated.  
5. Zoom → Ongoing Unavailability. Export CSV.  
