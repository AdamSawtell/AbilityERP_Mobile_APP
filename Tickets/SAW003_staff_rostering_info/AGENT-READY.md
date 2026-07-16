# SAW003 — Agent ready (deploy handoff)

**GitHub:** [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)  
**Source of truth:** [`DEPLOY.md`](DEPLOY.md)  
**Plugin:** `idempiere-plugins/com.aberp.rostering.staffinfo/`  
**Bundle:** `com.aberp.rostering.staffinfo` **`1.1.0.2026071517`**  
**SQL:** through **`26-show-partner-location-suburb.sql`** (+ `04-verify`)  
**Info Window UU:** `2b4ab146-0809-47c6-96f3-8b841d60a6bf` (must already exist)

## Prebuilt JAR in repo

`idempiere-plugins/com.aberp.rostering.staffinfo/release/com.aberp.rostering.staffinfo_1.1.0.2026071517.jar`  
(~52 KB known-good; reject ~29 KB stale builds)

Prefer host `./build.sh` when the target has `$IDEMPIERE_HOME`. Otherwise scp this release JAR and install per `DEPLOY.md` § JAR-only.

## What to ship (current)

| Piece | Why |
|-------|-----|
| JAR `1517` | Four filter ticks; Familiar; credential AND; **results single-select** (Related Info); scoped North |
| SQL `25` | Hide On Approved Leave / Has Future Shift from grid |
| SQL `26` | **Partner Location** suburb column in search results (String City/Name; not a filter) |

## Deploy choices

1. **Full:** `./deploy.sh` → SQL `01`→`26`→`04` + JAR + restart  
2. **Typical later host:** JAR-only `1517` + apply `26` if missing (and `25` if missing) → restart → Cache Reset / logout-in  

Do **not** wipe OSGi configuration cache.

## Environments already on this build

| Env | Host | State |
|-----|------|--------|
| Staging | `54.206.120.32:8080` | `1517` + SQL `26` |
| HCO Test | `http://3.25.86.128/webui/` | `1517` + SQL `26` · SSH `ubuntu` / `HCObusiness.pem` |

## Agent prompt (copy)

> Deploy SAW003 per `Tickets/SAW003_staff_rostering_info/DEPLOY.md` and `AGENT-READY.md`. Install JAR `1.1.0.2026071517` (build or use `release/…1517.jar`). If SQL through `25` is already applied, still run `sql/26-show-partner-location-suburb.sql` if missing. Restart, Cache Reset / logout-in. Smoke: results **single-select**; **Partner Location** suburb in grid; four default-on filter ticks; lean grid (no leave/future columns); Related Info follows one row. Report pass/fail.
