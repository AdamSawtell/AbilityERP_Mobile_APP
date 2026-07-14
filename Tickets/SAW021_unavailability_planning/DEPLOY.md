# SAW021 — Deploy to another build (agent)

**Ticket / slug:** `SAW021_unavailability_planning`  
**Kind:** idempiere · **JAR:** Yes (planned) · **Status:** in-progress  
**GitHub:** [#21](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/21)

## Required host access

- SSH · `psql` · WebUI Admin · restart / OSGi  
- Java 11 + `$IDEMPIERE_HOME` to build the Info Window JAR  
- Develop host: `ubuntu@13.210.248.141` — key `c:\Users\sawte\Documents\SSH Keys\HCObusiness.pem`

## Agent one-liner (when pack exists)

```bash
cd idempiere-plugins/com.aberp.unavailability.planning
# upload + rebuild host script (mirror SAW016 redeploy-hco.sh)
bash rebuild-hco.sh
# Cache Reset / logout-in. Do NOT wipe OSGi configuration cache.
```

## Package / bundle (planned)

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.unavailability.planning/` |
| Symbolic name | `com.aberp.unavailability.planning` |
| Pattern clone | `com.aberp.leave.planning` (SAW016) |
| Base table | `AbERP_OngoingUnavailability` |
| UI class | `com.aberp.unavailability.planning.info.UnavailabilityPlanningInfoWindow` |
| Develop WebUI | `http://13.210.248.141/webui/` |

## AbilityERP Admin access

Grant Info Window **Unavailability Planning** (+ report process if added) by role **name** to AbilityERP Admin, Admin, Rostering, Rostering TL, People and Culture, Manager People and Culture — and mirror window access from **Ongoing Unavailability** / **Unavailability & Leave (all)** where present. Smoke as Admin.

## Portability risks

- Never hardcode `AD_*_ID` — resolve by `*_UU` / name.  
- Never change existing client `*_UU` on HCO.  
- Reuse SAW016 Support Location EXISTS pattern (`ShiftStaff → Shift → MasterLocation`).  
- Nested SELECT in InfoColumn `selectclause` breaks `AccessSqlParser` — use DB functions for display.  
- Export CSV: `Filedownload.save(byte[])` only (no `zcommon` / `AMedia`).  
- Ongoing has **no** Unavailability Type — do not copy that criterion from Leave Planning.

## WebUI smoke (acceptance)

1. Cache Reset + re-login as Admin.  
2. Menu → **Unavailability Planning**.  
3. Set Planning Start/End (e.g. 01/01/2027–31/01/2027), Support Location blank (= all), Search.  
4. Expect ~49 overlapping headers on current HCO develop data; banner totals match grid.  
5. Zoom a row → Ongoing Unavailability opens; day lines still available on child tab.  
6. Filter Approver Status / Employee; Export CSV downloads matching rows.
