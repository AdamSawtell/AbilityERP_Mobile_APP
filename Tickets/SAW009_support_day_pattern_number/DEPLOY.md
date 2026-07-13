# SAW009 — Deploy to another build (agent)

**Ticket / slug:** `SAW009_support_day_pattern_number`  
**Kind:** idempiere · **JAR:** No · **Status:** done  
**GitHub:** [#9](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/9)

Point agents at **this file**. External customer text: [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md). HCO ID map: [`NOTES.md`](NOTES.md) → **HCO Future Deployments variables**.

## Required host access

- SSH to iDempiere host  
- `psql` as postgres (or equivalent) on DB `idempiere` / schema `adempiere`  
- WebUI AbilityERP Admin (Cache Reset / logout-in)  
- **No** OSGi console / **No** iDempiere restart

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
chmod +x deploy.sh && sudo ./deploy.sh
# Then WebUI: Cache Reset (or logout/in). Smoke as AbilityERP Admin.
```

Alternate (same SQL order):

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
sudo bash sql/run-install.sh "$(pwd)/sql"
```

Thin prod pack (if present on the workstation):

`Downloads\AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-*\` → follow `HOW-TO.txt` (`01-APPLY.sql`).

## Package (source of truth)

`idempiere-plugins/com.aberp.servicebooking.supportdays/`

| Step | File |
|------|------|
| 1 | `sql/00-preflight.sql` |
| 2 | `sql/01-add-support-day-columns.sql` |
| 3 | `sql/02-add-fields.sql` |
| 4 | `sql/03-backfill-from-pattern.sql` |
| 5 | `sql/04-sync-trigger.sql` |
| 6 | `sql/05-verify.sql` (via `deploy.sh`) |

Rollback: `sql/99-rollback.sql` (drops trigger + AD field/column rows owned by this ticket; physical DB columns kept unless uncommented).

## What the install does

1. Ensures `c_orderline.aberp_support_start_day` / `aberp_support_end_day` exist.  
2. AD columns on `C_OrderLine` use List **14 Day Roster Period** (same as Booking Generator Service Pattern Start/End Day).  
3. Fields on **Service Booking → Service Booking Line**.  
4. Backfills from linked `AbERP_ServicePattern` only (never invents day from weekday name alone).  
5. BEFORE INSERT/UPDATE trigger copies pattern days when `AbERP_ServicePattern_ID` is set/changed.

## Preflight UUs (fail closed)

| Object | Resolve by |
|--------|------------|
| Table `C_OrderLine` | `ad_table_uu` `fbab5be2-21b0-4f4f-b070-cd9d77efa238` or `tablename` |
| Tab Service Booking Line | `ad_tab_uu` `8b044105-bc30-4f81-b0d6-a45835d82f98` |
| List **14 Day Roster Period** | `ad_reference_uu` `5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd` |
| Elements Support Start/End Day | `ac9cf459-1755-4dfb-b46d-22091027402b` / `fbe588b0-561d-437c-b84d-4328185f0e9b` (or `columnname`) |
| Table `aberp_servicepattern` | must exist |

Owned insert UUs (new objects only): column `c0a90001-…` / `c0a90002-…`, field `c0a90003-…` / `c0a90004-…`.

## Portability / HCO hard rules

- If `AD_Column` / `AD_Field` already exists on the target → **UPDATE properties only; never overwrite existing `*_UU`**.  
- Do not shrink existing physical column length (script uses `GREATEST(fieldlength, 5)` / `ADD COLUMN IF NOT EXISTS`).  
- List **names** may start on Sunday or Monday depending on client roster alignment — reuse the client’s **14 Day Roster Period** names as-is (do not recalculate from weekday).  
- Pre-existing weekday-only string values (`Monday`) are replaced only where `AbERP_ServicePattern_ID` links a pattern (backfill/trigger).  
- See `NOTES.md` for HCO Test observed local IDs.

## AbilityERP Admin access

No new window / process / Info Window / menu. Fields sit on existing **Service Booking**. Admin needs existing Service Booking window access (pre-existing). Smoke **as AbilityERP Admin** (on HCO: SuperUser → operational **Admin** if that is the login role).

## Restart / cache

- **No** restart  
- **Yes** Cache Reset / logout-in after SQL

## WebUI smoke

1. Log in as AbilityERP Admin.  
2. Open **Service Booking → Service Booking Line**.  
3. Confirm **Support Start Day** / **Support End Day** show numbered labels (e.g. `02 - Monday`, `09 - Monday`, or client-equivalent list names).  
4. Link/set **AbERP ServicePattern** → days copy from pattern Start/End.  
5. Confirm Start and End can differ; 14-day pattern Mondays remain distinguishable.  
6. Line with no pattern link: days stay blank / unchanged — no false day-01 from weekday alone.  
7. Booking Generator → Service Pattern Line still shows numbered days (unchanged).

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW009_support_day_pattern_number-20260713`  
- Thin prod: `Downloads\AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-20260713`

## External ticket text

[`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)
